import Foundation

public struct ReplicaState<T: AnyObject & Sendable> {
    var loading: Bool
    var data: ReplicaData<T>?
    var error: LoadingError?
    var observingState: ObservingState
    var dataRequested: Bool
    var preloading: Bool
    var loadingFromStorageRequired: Bool

    var hasFreshData: Bool {
        return data?.isFresh == true
    }

    static func createEmpty(hasStorage: Bool) -> ReplicaState<T> {
        return ReplicaState(
            loading: false,
            data: nil,
            error: nil,
            observingState: ObservingState(),
            dataRequested: false,
            preloading: false,
            loadingFromStorageRequired: hasStorage
        )
    }

    func getLoadable() -> LoadableReplicaState<T> {
        return LoadableReplicaState(
            loading: loading,
            data: data?.value,
            error: error.map { CombinedLoadingError(errors: [$0]) }
        )
    }

    func copy(
        observingState: ObservingState? = nil,
        loading: Bool? = nil,
        dataRequested: Bool? = nil,
        preloading: Bool? = nil,
        loadingFromStorageRequired: Bool? = nil
    ) -> ReplicaState<T> {
        ReplicaState(
            loading: loading ?? self.loading,
            observingState: observingState ?? self.observingState,
            dataRequested: dataRequested ?? self.dataRequested,
            preloading: preloading ?? self.preloading,
            loadingFromStorageRequired: loadingFromStorageRequired ?? self.loadingFromStorageRequired
        )
    }
}
