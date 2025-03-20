/// Определяет базовое состояние загрузки данных для объекта.
public protocol AbstractLoadable {
    associatedtype T

    /// Указывает, выполняется ли загрузка в данный момент.
    var isLoading: Bool { get }

    /// Данные, если они доступны, или nil, если загрузка ещё не завершена или произошла ошибка.
    var data: T? { get }

    /// Ошибка загрузки, если она произошла, или nil, если ошибок нет.
    var error: CombinedLoadingError? { get }
}
