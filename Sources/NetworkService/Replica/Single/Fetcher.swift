/// Извлекает данные с сервера. Может выбросить ошибку при неудаче.
public protocol Fetcher<T> {
    associatedtype T

    /// Выполняет запрос данных.
    func fetch() async throws -> T
}
