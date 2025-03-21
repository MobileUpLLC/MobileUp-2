import Foundation

enum LoggerPlugin {
    nonisolated(unsafe) static let instance = NetworkLoggerPlugin(configuration: configuration)

    nonisolated(unsafe) private static let configuration = NetworkLoggerPlugin.Configuration(output: defaultOutput, logOptions: .verbose)
    
    private static func defaultOutput(target: TargetType, items: [String]) {
        var logMessage = "---------------------------REQUEST START---------------------------\n"

        for item in items {
            logMessage.append(contentsOf: "\n" + item)
        }

        logMessage.append(contentsOf: "\n\n---------------------------REQUEST END-----------------------------\n\n")
        
        Log.networkService.debug(logEntry: .text(logMessage))
    }
}
