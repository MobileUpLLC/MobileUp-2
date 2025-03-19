import Foundation

/// Настройки поведения реплики.
public struct ReplicaSettings: Sendable {
    /// Время, через которое данные считаются устаревшими
    public let staleTime: TimeInterval?

    /// Время, через которое данные очищаются при отсутствии наблюдателей
    public let clearTime: TimeInterval?

    /// Время, через которое ошибка очищается при отсутствии наблюдателей
    public let clearErrorTime: TimeInterval?

    /// Время, через которое запрос отменяется при отсутствии наблюдателей
    public let cancelTime: TimeInterval?

    /// Указывает, нужно ли обновлять устаревшие данные при добавлении активного наблюдателя.
    public let isNeedToRefreshOnActiveObserverAdded: Bool

    /// Указывает, нужно ли обновлять устаревшие данные при восстановлении сети, если есть активные наблюдатели.
    public let isNeedToRefreshOnNetworkConnection: Bool

    public init(
        staleTime: TimeInterval? = nil,
        clearTime: TimeInterval? = nil,
        clearErrorTime: TimeInterval? = 0.25,
        cancelTime: TimeInterval? = 0.25,
        isNeedToRefreshOnActiveObserverAdded: Bool = true,
        isNeedToRefreshOnNetworkConnection: Bool = true
    ) {
        self.staleTime = staleTime
        self.clearTime = clearTime
        self.clearErrorTime = clearErrorTime
        self.cancelTime = cancelTime
        self.isNeedToRefreshOnActiveObserverAdded = isNeedToRefreshOnActiveObserverAdded
        self.isNeedToRefreshOnNetworkConnection = isNeedToRefreshOnNetworkConnection
    }

    /// Настройки для реплики без автоматического поведения.
    public static let withoutBehavior = ReplicaSettings(
        staleTime: nil,
        clearTime: nil,
        clearErrorTime: nil,
        cancelTime: nil,
        isNeedToRefreshOnActiveObserverAdded: false,
        isNeedToRefreshOnNetworkConnection: false
    )
}
