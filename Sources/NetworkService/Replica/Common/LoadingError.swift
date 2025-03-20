/// Представляет собой ошибку, возникшую во время сетевого запроса.
public struct LoadingError {
    public let reason: LoadingReason
    public let error: ServerError
}
