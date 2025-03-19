import Foundation

public struct ReplicaTag: Hashable {}

/// Реплика с расширенным API для управления данными.
public protocol PhysicalReplica<T>: Replica {
    var id: UUID { get }
    var name: String { get }
    var settings: ReplicaSettings { get }
    var tags: Set<ReplicaTag> { get }

    /// Поток состояний реплики.
    var stateFlow: AsyncStream<ReplicaState<T>> { get async }

    /// Поток событий реплики.
    var eventFlow: AsyncStream<ReplicaEvent<T>> { get async }

    func setData(_ data: T) async throws
    func mutateData(_ transform: @escaping (T) -> T) async throws
    func invalidate(mode: InvalidationMode) async throws
    func makeFresh() async throws
    func cancel() async
    func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async
    func clearError() async throws
    func beginOptimisticUpdate(_ update: OptimisticUpdate<T>) async throws
    func commitOptimisticUpdate(_ update: OptimisticUpdate<T>) async throws
    func rollbackOptimisticUpdate(_ update: OptimisticUpdate<T>) async throws
}

extension PhysicalReplica {
    var currentState: ReplicaState<T> {
        get async {
            var lastState: ReplicaState<T>?
            for await state in await stateFlow {
                lastState = state
                break
            }
            return lastState ?? .createEmpty(hasStorage: false)
        }
    }
}

//public extension PhysicalReplica {
//    /// Выполняет операцию с оптимистичным обновлением данных реплики.
//    /// - Parameters:
//    ///   - update: Обновление, применяемое немедленно к наблюдаемому состоянию.
//    ///   - onSuccess: Коллбек при успешном завершении операции.
//    ///   - onError: Коллбек при возникновении ошибки.
//    ///   - onCanceled: Коллбек при отмене операции.
//    ///   - onFinished: Коллбек после завершения (успех, ошибка или отмена).
//    ///   - operation: Основная операция, возвращающая результат.
//    /// - Returns: Результат выполнения операции.
//    /// - Throws: Ошибка, если операция не удалась.
//    func withOptimisticUpdate<R>(
//        update: OptimisticUpdate<ReplicaData>,
//        onSuccess: (@Sendable () async -> Void)? = nil,
//        onError: (@Sendable (Error) async -> Void)? = nil,
//        onCanceled: (@Sendable () async -> Void)? = nil,
//        onFinished: (@Sendable () async -> Void)? = nil,
//        operation: () async throws -> R
//    ) async throws -> R {
//        try await OptimisticUpdate<ReplicaData>.withUpdate(
//            begin: { try await self.beginOptimisticUpdate(update) },
//            commit: { try await self.commitOptimisticUpdate(update) },
//            rollback: { try await self.rollbackOptimisticUpdate(update) },
//            onSuccess: onSuccess,
//            onError: onError,
//            onCanceled: onCanceled,
//            onFinished: onFinished,
//            operation: operation
//        )
//    }
//}
