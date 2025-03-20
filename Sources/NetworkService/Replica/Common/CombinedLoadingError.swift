/// Представляет набор ошибок, возникших во время сетевого запроса.
public struct CombinedLoadingError {
    public let errors: [LoadingError]

    /// Создаёт комбинированную ошибку из списка ошибок.
    /// - Parameter errors: Список ошибок. Если пуст, создаётся с одной неизвестной ошибкой.
    public init(errors: [LoadingError]) {
        self.errors = errors
    }

    /// Создаёт комбинированную ошибку из одной ошибки.
    /// - Parameters:
    ///   - reason: Причина ошибки.
    ///   - error: Серверная ошибка с деталями.
    public init(reason: LoadingReason, error: ServerError) {
        self.errors = [LoadingError(reason: reason, error: error)]
    }

    /// Возвращает первую ошибку из списка.
    public var firstServerError: ServerError {
        errors[0].error
    }

    /// Возвращает первую причину ошибки из списка.
    public var firstReason: LoadingReason {
        errors[0].reason
    }
}
