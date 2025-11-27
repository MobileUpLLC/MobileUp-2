//
//  MUNNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public actor MUNNetworkService<Target: MUNAPITarget> {
    private var moyaProvider: MoyaProvider<Target>
    private var accessTokenRefresher: MUNAccessTokenRefresher?

    private var tokenRefreshFailureHandler: (() async -> Void)?
    private var tokenRefreshTask: _Concurrency.Task<Void, Error>?
    private var activeRequests: Set<NetworkServiceActiveRequest> = []
    private var requestsPendingTokenRefresh: Set<UUID> = []

    public init(
        session: Session = MoyaProvider<Target>.defaultAlamofireSession(),
        plugins: [any PluginType] = [],
    ) {
        self.moyaProvider = MoyaProvider<Target>.init(
            stubClosure: { $0.isMockEnabled ? .delayed(seconds: 1.5) : .never },
            session: session,
            plugins: plugins
        )
    }

    public func setAuthorizationObjects(
        provider: MUNAccessTokenProvider,
        refresher: MUNAccessTokenRefresher,
        tokenRefreshFailureHandler: @escaping @Sendable () async -> Void
    ) {
        self.accessTokenRefresher = refresher
        self.tokenRefreshFailureHandler = tokenRefreshFailureHandler

        let accessTokenPlugin = AccessTokenPlugin(accessTokenProvider: provider)
        self.moyaProvider = MoyaProvider<Target>(
            stubClosure: moyaProvider.stubClosure,
            session: moyaProvider.session,
            plugins: moyaProvider.plugins + [accessTokenPlugin]
        )
    }
    
    public func cancelRequests() {
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
        
        activeRequests.forEach { request in
            request.task.cancel()
        }

        activeRequests.removeAll()
        requestsPendingTokenRefresh.removeAll()

        _Concurrency.Task { @MUNLogger in
            MUNLogger.sharedLoggable?.log(type: .info, "All network requests have been cancelled")
        }
    }

    public func executeRequest<T: Decodable & Sendable>(
        target: Target,
        isTokenRefreshed: Bool = false
    ) async throws -> T {
        let requestId = UUID()
        let requestTask = _Concurrency.Task<T, any Error> {
            try await performExecuteRequestWithDecodable(
                requestId: requestId,
                target: target,
                isTokenRefreshed: isTokenRefreshed
            )
        }
        
        saveActiveRequest(
            requestId: requestId,
            isAccessTokenRequired: target.isAccessTokenRequired,
            task: requestTask
        )
        
        do {
            let result = try await requestTask.value
            completeRequest(requestId)
            return result
        } catch {
            completeRequest(requestId)
            throw error
        }
    }

    public func executeRequest(target: Target, isTokenRefreshed: Bool = false) async throws {
        let requestId = UUID()
        let requestTask = _Concurrency.Task<Void, any Error> {
            try await performExecuteRequestWithoutDecodable(
                requestId: requestId,
                target: target,
                isTokenRefreshed: isTokenRefreshed
            )
        }
        
        saveActiveRequest(
            requestId: requestId,
            isAccessTokenRequired: target.isAccessTokenRequired,
            task: requestTask
        )
        
        do {
            try await requestTask.value
            completeRequest(requestId)
        } catch {
            completeRequest(requestId)
            throw error
        }
    }

    private func performExecuteRequestWithDecodable<T: Decodable & Sendable>(
        requestId: UUID,
        target: Target,
        isTokenRefreshed: Bool
    ) async throws -> T {
        do {
            let response = try await performRequest(target: target).get()
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            return try filteredResponse.map(T.self)
        } catch {
            try await resolveRequestError(
                error,
                requestId: requestId,
                target: target,
                isTokenRefreshed: isTokenRefreshed
            )
            return try await performExecuteRequestWithDecodable(
                requestId: requestId,
                target: target,
                isTokenRefreshed: true
            )
        }
    }

    private func performExecuteRequestWithoutDecodable(
        requestId: UUID,
        target: Target,
        isTokenRefreshed: Bool
    ) async throws {
        do {
            let response = try await performRequest(target: target).get()
            let _ = try response.filterSuccessfulStatusCodes()
        } catch {
            try await resolveRequestError(
                error,
                requestId: requestId,
                target: target,
                isTokenRefreshed: isTokenRefreshed
            )
            try await performExecuteRequestWithoutDecodable(
                requestId: requestId,
                target: target,
                isTokenRefreshed: true
            )
        }
    }

    private func saveActiveRequest<T>(
        requestId: UUID,
        isAccessTokenRequired: Bool,
        task: _Concurrency.Task<T, Error>
    ) {
        activeRequests.insert(
            NetworkServiceActiveRequest(
                id: requestId, 
                isAccessTokenRequired: isAccessTokenRequired,
                task: .init(task)
            )
        )
    }

    private func performRequest(target: Target) async throws -> Result<Response, MoyaError> {
        try _Concurrency.Task.checkCancellation()
        let result = await withCheckedContinuation { continuation in
            moyaProvider.request(target) { continuation.resume(returning: $0) }
        }
        try _Concurrency.Task.checkCancellation()
        return result
    }

    private func completeRequest(_ requestId: UUID) {
        if let index = activeRequests.firstIndex(where: { $0.id == requestId }) {
            activeRequests.remove(at: index)
        }
        requestsPendingTokenRefresh.remove(requestId)
    }

    private func resolveRequestError(
        _ error: Error,
        requestId: UUID,
        target: Target,
        isTokenRefreshed: Bool
    ) async throws {
        _Concurrency.Task { @MUNLogger in
            MUNLogger.sharedLoggable?.log(type: .error, error.localizedDescription)
        }

        guard let moyaError = error as? MoyaError,
            target.isAccessTokenRequired,
            target.isRefreshTokenRequest == false,
            isTokenRefreshed == false,
            let statusCode = moyaError.response?.statusCode,
            [401, 403, 409].contains(statusCode)
        else {
            throw error
        }

        if let tokenRefreshTask {
            return try await tokenRefreshTask.value
        } else if requestsPendingTokenRefresh.contains(requestId) {
            return
        }

        requestsPendingTokenRefresh = Set(activeRequests.compactMap { $0.isAccessTokenRequired ? $0.id : nil })
        tokenRefreshTask = _Concurrency.Task { [weak self] in
            guard let accessTokenRefresher = await self?.accessTokenRefresher else {
                throw error
            }

            try await accessTokenRefresher.refresh()
        }

        do {
            try await tokenRefreshTask?.value
            tokenRefreshTask = nil
        } catch {
            await tokenRefreshFailureHandler?()
            throw error
        }
    }
}
