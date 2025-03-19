import Foundation

struct DoOnStateCondition<T: AnyObject & Sendable>: ReplicaBehaviour {
    let condition: @Sendable (ReplicaState<T>) -> Bool
    let startDelay: TimeInterval
    let action: @Sendable (any PhysicalReplica<T>) async throws -> ()

    func setup(replica: any PhysicalReplica<T>) async {
        _Concurrency.Task { @Sendable in
            while true {
                let state = await replica.currentState

                if condition(state) {
                    try? await _Concurrency.Task.sleep(nanoseconds: UInt64(startDelay * 1_000_000_000))
                    try await action(replica)
                }
                try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // Проверка каждые 100мс
            }
        }
    }
}
