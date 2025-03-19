import Foundation

struct DoOnEvent<T: AnyObject & Sendable>: ReplicaBehaviour {
    let action: @Sendable (any PhysicalReplica<T>, ReplicaEvent<T>) async -> Void

    func setup(replica: any PhysicalReplica<T>) async {
        _Concurrency.Task { @Sendable in
            for await event in replica.eventFlow {
                await action(replica, event)
            }
        }
    }
}
