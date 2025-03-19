//
//  File 2.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 19.03.2025.
//

import Foundation

class ReplicaObserverImpl<T: AnyObject & Sendable>: ReplicaObserver {

 //   private static let idGenerator = IDGenerator()

    private let observerHost: any ReplicaObserverHost
    private let replicaStateFlow: AsyncStream<ReplicaState<T>>
    private let replicaEventFlow: AsyncStream<ReplicaEvent<T>>
    private let observersController: any ObserversController<T>

    private var stateContinuation: AsyncStream<LoadableReplicaState<T>>.Continuation?
    private var errorContinuation: AsyncStream<LoadingError>.Continuation?

    private var observerControllingTask: _Concurrency.Task<Void, Never>?
    private var stateObservingTask: _Concurrency.Task<Void, Never>?
    private var errorsObservingTask: _Concurrency.Task<Void, Never>?

    init(
        observerHost: any ReplicaObserverHost,
        replicaStateFlow: AsyncStream<ReplicaState<T>>,
        replicaEventFlow: AsyncStream<ReplicaEvent<T>>,
        observersController: any ObserversController<T>
    ) {
        self.observerHost = observerHost
        self.replicaStateFlow = replicaStateFlow
        self.replicaEventFlow = replicaEventFlow
        self.observersController = observersController

        _Concurrency.Task { [weak self] in
            guard let self else {
                return
            }
            await self.launchObserverControlling()
            await self.launchStateObserving()
            await self.launchLoadingErrorsObserving()
        }
    }

    func stateFlow() async -> AsyncStream<LoadableReplicaState<T>> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(LoadableReplicaState<T>())
        }
    }

    func loadingErrorFlow() async -> AsyncStream<LoadingError> {
        AsyncStream { continuation in
            self.errorContinuation = continuation
        }
    }

    func cancelObserving() async {
        observerControllingTask?.cancel()
        observerControllingTask = nil

        stateObservingTask?.cancel()
        stateObservingTask = nil

        errorsObservingTask?.cancel()
        errorsObservingTask = nil

        stateContinuation?.finish()
        errorContinuation?.finish()
    }

    private func launchObserverControlling() async {
        observerControllingTask = _Concurrency.Task { @Sendable [weak self, observerHost, observersController] in
            guard let self else { return }
            let observerId = await Self.idGenerator.next()
            let activeFlow = await observerHost.observerActive()

            do {
                var initialActive: Bool?
                for await active in activeFlow {
                    if let initial = initialActive {
                        if active {
                            await observersController.onObserverActive(observerId: observerId)
                        } else {
                            await observersController.onObserverInactive(observerId: observerId)
                        }
                    } else {
                        await observersController.onObserverAdded(observerId: observerId, active: active)
                        initialActive = active
                    }
                }
            }
            await observersController.onObserverRemoved(observerId: observerId)
        }
    }

    private func launchStateObserving() async {
        stateObservingTask = _Concurrency.Task { @Sendable [weak self, replicaStateFlow, observerHost] in
            guard let self else { return }
            let activeFlow = await observerHost.observerActive()
            for await (state, active) in zip(replicaStateFlow, activeFlow) {
                if active {
                    stateContinuation?.yield(state.toLoadable())
                }
            }
        }
    }

    private func launchLoadingErrorsObserving() async {
        errorsObservingTask = _Concurrency.Task { @Sendable [weak self, replicaEventFlow, observerHost] in
            guard let self else { return }
            let activeFlow = await observerHost.observerActive()
            for await (event, active) in zip(replicaEventFlow, activeFlow) {
                if active, case let .loadingFinished(.error(exception)) = event {
                    errorContinuation?.yield(LoadingError(reason: .normal, exception: exception))
                }
            }
        }
    }
}
