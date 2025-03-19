import Foundation

actor StaleAfterGivenTime<T: AnyObject & Sendable>: ReplicaBehaviour {
    private let timeInterval: TimeInterval
    private var staleTask: _Concurrency.Task<Void, Never>?

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    func setup(replica: any PhysicalReplica<T>) async {
        _Concurrency.Task { @Sendable in
            for await event in replica.eventFlow {
                switch event {
                case .freshness(let event):
                    switch event {
                    case .freshened:
                        staleTask?.cancel()
                        staleTask = _Concurrency.Task {
                            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(timeInterval * 1_000_000_000))
                            try? await replica.invalidate(mode: .dontRefresh)
                        }
                    case .becameStale:
                        staleTask?.cancel()
                        staleTask = nil
                    }
                case .cleared:
                    staleTask?.cancel()
                    staleTask = nil
                default:
                    break
                }
            }
        }
    }
}
