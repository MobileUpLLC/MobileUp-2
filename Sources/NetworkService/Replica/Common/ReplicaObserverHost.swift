import Foundation

protocol ReplicaObserverHost: Sendable {
    func observerActive() async -> AsyncStream<Bool>
}

private actor StandardReplicaObserverHost: ReplicaObserverHost {
    private let activeStreamProvider: @Sendable () async -> AsyncStream<Bool>

    init(activeStreamProvider: @escaping @Sendable () async -> AsyncStream<Bool>) {
        self.activeStreamProvider = activeStreamProvider
    }

    func observerActive() async -> AsyncStream<Bool> {
        await activeStreamProvider()
    }
}
