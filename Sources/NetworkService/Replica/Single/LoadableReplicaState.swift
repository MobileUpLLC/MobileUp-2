import Foundation

/// Состояние реплики, которое можно наблюдать во View
/// Содержит минимальный набор полей в отличие от ReplicaState.
public struct LoadableReplicaState<T>: AbstractLoadable {
    /// Указывает, выполняется ли загрузка в данный момент.
    public let loading: Bool

    /// Данные, если они доступны, или nil, если загрузка ещё не завершена или произошла ошибка.
    public let data: T?

    /// Ошибка загрузки, если она произошла, или nil, если ошибок нет.
    public let error: CombinedLoadingError?

    public init(
        loading: Bool = false,
        data: T? = nil,
        error: CombinedLoadingError? = nil
    ) {
        self.loading = loading
        self.data = data
        self.error = error
    }

    /// Преобразует данные с помощью функции transform.
    public func mapData<R>(_ transform: (T) -> R) -> LoadableReplicaState<R> {
        LoadableReplicaState<R>(
            loading: loading,
            data: data.map(transform),
            error: error
        )
    }
}
