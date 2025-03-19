import Foundation

/// Наблюдатель за репликой, предоставляющий обновления состояния и ошибок.
public protocol ReplicaObserver<T> {
    associatedtype T

    /// Поток состояний реплики для отображения на UI.
  //  var stateFlow: AsyncStream<LoadableReplicaState<T>> { get }
    func stateFlow() async -> AsyncStream<LoadableReplicaState<T>>
    /// Поток событий ошибок загрузки.
   // var loadingErrorFlow: AsyncStream<LoadingError> { get }

    func loadingErrorFlow() async -> AsyncStream<LoadingError>

    /// Прекращает наблюдение вручную.
    func cancelObserving() async
}

public extension ReplicaObserver {
    /// Текущее состояние реплики (асинхронный доступ).
    var currentState: LoadableReplicaState<T> {
        get async {
            var lastState: LoadableReplicaState<T> = LoadableReplicaState()
            for await state in await stateFlow() {
                lastState = state
                break
            }
            return lastState
        }
    }
}
