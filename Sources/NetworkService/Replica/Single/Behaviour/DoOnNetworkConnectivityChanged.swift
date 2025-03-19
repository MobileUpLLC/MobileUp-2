import Foundation

struct DoOnNetworkConnectivityChanged<T: AnyObject & Sendable>: ReplicaBehaviour {
    private let networkConnectivityProvider: any NetworkConnectivityProvider
    private let action: @Sendable (any PhysicalReplica<T>, Bool) async -> Void

    init(
        networkConnectivityProvider: any NetworkConnectivityProvider,
        action: @escaping @Sendable (any PhysicalReplica<T>, Bool) async -> Void
    ) {
        self.networkConnectivityProvider = networkConnectivityProvider
        self.action = action
    }

    func setup(replica: any PhysicalReplica<T>) async {
        _Concurrency.Task { @Sendable [networkConnectivityProvider] in
            var isFirstEvent = true
            for await connected in await networkConnectivityProvider.observeNetworkChanges() {
                if isFirstEvent {
                    isFirstEvent = false
                    continue // Пропускаем первое событие, аналог .drop(1)
                }
                await action(replica, connected)
            }
        }
    }
}
