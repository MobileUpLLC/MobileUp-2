import Foundation

/// Событие, произошедшее в реплике.
public enum ReplicaEvent<T: Sendable>: Sendable {
    /// События, связанные с загрузкой.
    case loading(LoadingEvent<T>)
    /// События, связанные со свежестью данных.
    case freshness(FreshnessEvent)
    /// Данные и ошибки очищены.
    case cleared
    /// Изменение количества наблюдателей.
    case observerCountChanged(ObserversCountInfo)
}

public enum LoadingFinished<T: Sendable>: Sendable {
    /// Успешная загрузка с данными.
    case success(data: T)
    /// Загрузка отменена.
    case canceled
    /// Ошибка загрузки.
    case error(ServerError)
}

public enum LoadingEvent<T: Sendable>: Sendable {
    /// Начало загрузки.
    case loadingStarted
    /// Данные загружены из хранилища.
    case dataFromStorageLoaded(data: T)
    /// Результат завершения загрузки.
    case loadingFinished(LoadingFinished<T>)
}

public enum FreshnessEvent: Sendable {
    /// Данные стали свежими.
    case freshened
    /// Данные устарели.
    case becameStale
}

public struct ObserversCountInfo: Sendable {
    let count: Int
    let activeCount: Int
    let previousCount: Int
    let previousActiveCount: Int
}
