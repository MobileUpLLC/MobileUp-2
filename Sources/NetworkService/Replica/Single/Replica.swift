import Foundation

/// Протокол базовой реплики с минимальным API.
public protocol Replica<T> {
    associatedtype T: AnyObject & Sendable

    /// Начинает наблюдение за репликой.
    /// - Parameters:
    ///   - observerLifetime: Объект, определяющий жизненный цикл наблюдателя.
    ///   - isActive: Асинхронный поток, указывающий, активен ли наблюдатель.
    /// - Returns: Объект наблюдателя с доступом к состоянию и событиям ошибок.
    /// - Note: Наблюдатель прекращает работу, когда `observerLifetime` отменяется.
    func observe(
        lifetime observerLifetime: any Cancellable,
        isActive: AsyncStream<Bool>
    ) -> any ReplicaObserver

    /// Загружает свежие данные из сети.
    /// - Note: Не вызывает новый запрос, если другой уже выполняется.
    func refresh() async

    /// Загружает свежие данные из сети, если текущие данные устарели.
    /// - Note: Не вызывает новый запрос, если другой уже выполняется.
    func revalidate() async

    /// Загружает и возвращает данные.
    /// - Parameter forceRefresh: Принудительно выполняет запрос, даже если данные свежие.
    /// - Returns: Свежие данные.
    /// - Throws: Ошибка, если загрузка не удалась.
    /// - Note: Всегда возвращает свежие данные, выполняя запрос при необходимости.
    func getData(forceRefresh: Bool) async throws -> T
}

public extension Replica {
    /// Загружает и возвращает данные без принудительного обновления.
    func getData() async throws -> T {
        try await getData(forceRefresh: false)
    }
}
