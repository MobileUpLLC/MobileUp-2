import Foundation
import os

extension Log {
    static let networkService = Log(subsystem: subsystem, category: "NetworkService")
    static let refreshTokenFlow = Log(subsystem: subsystem, category: "refreshTokenFlow")
    static let mockableMobileApiTarget = Log(subsystem: subsystem, category: "MockableMobileApiTarget")

    private static let subsystem = Bundle.main.bundleIdentifier ?? ""
}

actor LoggingConfiguration {
    static let shared = LoggingConfiguration()
    private var _isRelease: Bool?

    /// Метод конфигурации, который можно вызвать только один раз.
    func configure(isRelease: Bool) {
        precondition(_isRelease == nil, "LoggingConfiguration уже настроена")
        _isRelease = isRelease
    }

    /// Асинхронный метод для получения значения isRelease.
    func getIsRelease() -> Bool {
        guard let value = _isRelease else {
            assertionFailure("LoggingConfiguration не настроена. Необходимо вызвать configure(isRelease:) до использования.")
            return true
        }
        return value
    }
}

public struct Log: Sendable {
    enum LogEntry: Sendable{
        case text(String)
    }

    private let logger: Logger
    private let category: String

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.category = category
    }
    
    /// Only during debugging.
    ///
    /// Examples:
    /// 1. Intermediate calculation results for algrorithm.
    ///
    /// Not persisted.
    func debug(logEntry: LogEntry) {
        log(level: .debug, logEntry: logEntry)
    }
    
    /// Not essential for troubleshooting.
    ///
    /// Examples:
    /// 1. User logged in/logged out.
    /// 2. User changed language/theme/settings.
    ///
    /// Persisted only during log collect
    func info(logEntry: LogEntry) {
        log(level: .info, logEntry: logEntry)
    }
    
    /// Essential for troubleshooting.
    ///
    /// Examples:
    /// 1. Any server requests, successful responses.
    ///
    /// Persisted up to a storage limit
    func `default`(logEntry: LogEntry) {
        log(level: .default, logEntry: logEntry)
    }
    
    /// Error during execution.
    ///
    /// Examples:
    /// 1. Server returns error. Error is handled by app, so it's not a bug.
    ///
    /// Persisted up to a storage limit
    func error(logEntry: LogEntry) {
        log(level: .error, logEntry: logEntry)
    }
    
    /// Bug in program.
    ///
    /// Examples:
    /// 1. Server returns "-1" as user id. From data perspective it's valid, still Int,
    /// but can lead to undefined behavior.
    ///
    /// Persisted up to a storage limit
    func fault(logEntry: LogEntry) {
        log(level: .fault, logEntry: logEntry)
    }
    
    /// Disable logging for release builds.
    private func log(level: OSLogType, logEntry: LogEntry) {
        ConcurrencyTask { @Sendable in
            if await LoggingConfiguration.shared.getIsRelease() {
                return
            }

            let logMessage = getLogMessage(logEntry: logEntry)
            logger.log(level: level, "\(logMessage)")
        }
    }
    
    private func getLogMessage(logEntry: LogEntry) -> String {
        switch logEntry {
        case .text(let value):
            return value
        }
    }
}

