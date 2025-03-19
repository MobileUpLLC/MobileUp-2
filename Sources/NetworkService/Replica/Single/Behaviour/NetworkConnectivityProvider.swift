import Foundation

protocol NetworkConnectivityProvider: Sendable {
    var isConnected: Bool { get async }
    func observeNetworkChanges() async -> AsyncStream<Bool>
}
