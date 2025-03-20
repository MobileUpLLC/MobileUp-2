import Foundation

typealias OptimisticUpdate<T> = (T) -> T

/// Управляет выполнением оптимистичных (до подтверждения сервером) обновлений. 
actor OptimisticUpdateManager {
    /// Выполняет оптимистичное обновление с указанными действиями для начала, подтверждения, отката и обработки результатов.
    /// - Parameters:
    ///   - begin: Действие, выполняемое перед началом операции.
    ///   - commit: Действие, выполняемое при успешном завершении.
    ///   - rollback: Асинхронное действие для отката при ошибке или отмене.
    ///   - onSuccess: Опциональный callback для успеха.
    ///   - onError: Опциональный callback для обработки ошибки.
    ///   - onCanceled: Опциональный callback для отмены.
    ///   - onFinished: Опциональный callback, вызываемый в конце независимо от результата.
    ///   - block: Асинхронный блок, выполняющий основную операцию.
    /// - Returns: Результат выполнения блока.
    /// - Throws: Перебрасывает ошибки из блока или отмену.
    func performOptimisticUpdate<T: Sendable>(
        begin: () -> Void,
        commit: () -> Void,
        rollback: () async -> Void,
        onSuccess: (() async -> Void)? = nil,
        onError: ((Error) async -> Void)? = nil,
        onCanceled: (() async -> Void)? = nil,
        onFinished: (() async -> Void)? = nil,
        block: () async throws -> T
    ) async throws -> T {
        begin()
        do {
            let result = try await block()
            commit()
            await onSuccess?()
            await onFinished?()
            return result
        } catch is CancellationError {
            await rollback()
            await onCanceled?()
            await onFinished?()
            throw CancellationError()
        } catch {
            await rollback()
            await onError?(error)
            await onFinished?()
            throw error
        }
    }
}

extension Array {
    /// Применяет все оптимистичные обновления к данным.
    /// - Parameter data: Исходные данные.
    /// - Returns: Данные с применёнными обновлениями.
    func applyAll<T>(to data: T) -> T where Element == OptimisticUpdate<T> {
        reduce(data) { currentData, update in
            update(currentData)
        }
    }
}
