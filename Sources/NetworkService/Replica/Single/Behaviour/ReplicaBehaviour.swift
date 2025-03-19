protocol ReplicaBehaviour<T> {
    associatedtype T: AnyObject & Sendable 

    func setup(replica: any PhysicalReplica<T>) async
}
