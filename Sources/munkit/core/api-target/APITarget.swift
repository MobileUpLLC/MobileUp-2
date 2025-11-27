//
//  APITarget.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public protocol MUNAPITarget: TargetType, AccessTokenAuthorizable, Sendable {
    var parameters: [String: Sendable] { get }
    var isAccessTokenRequired: Bool { get }
    var isRefreshTokenRequest: Bool { get }
    var isMockEnabled: Bool { get }
    var mockFileName: String? { get }
}

extension MUNAPITarget {
    public var sampleData: Data { getSampleData() }

    func getSampleDataFromFileWithName(_ mockFileName: String) -> Data {
        let logStart = "For the request \(path), mock data"
        let mockExtension = "json"

        guard let mockFileUrl = Bundle.main.url(forResource: mockFileName, withExtension: mockExtension) else {
            _Concurrency.Task { @MUNLogger in
                MUNLogger.sharedLoggable?
                    .log(type: .debug, "🕸️💽🚨 \(logStart) \(mockFileName).\(mockExtension) not found.")
            }
            return Data()
        }

        do {
            let data = try Data(contentsOf: mockFileUrl)
            _Concurrency.Task { @MUNLogger in
                MUNLogger.sharedLoggable?.log(
                    type: .debug,
                    "🕸️💽✅ \(logStart) successfully read from URL: \(mockFileUrl)."
                )
            }
            return data
        } catch {
            _Concurrency.Task { @MUNLogger in
                MUNLogger.sharedLoggable?.log(
                    type: .debug,
                    "🕸️💽🚨\n\(logStart) from file \(mockFileName).\(mockExtension) could not be read.\nError: \(error)"
                )
            }
            return Data()
        }
    }

    private func getSampleData() -> Data {
        guard let mockFileName else {
            let path = path
            _Concurrency.Task { @MUNLogger in
                MUNLogger.sharedLoggable?.log(type: .debug, "🕸️💽🆓 The request \(path) does not use mock data.")
            }
            return Data()
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}
