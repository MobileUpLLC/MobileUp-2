import Foundation

/// Содержит информацию о наблюдателях реплики.
struct ObservingState: Equatable {
    let observerIds: Set<UUID>
    let activeObserverIds: Set<UUID>
    let observingTime: ObservingTime

    /// Количество наблюдателей.
    var observerCount: Int { observerIds.count }

    /// Количество активных наблюдателей.
    var activeObserverCount: Int { activeObserverIds.count }

    /// Текущий статус наблюдения, основанный на количестве наблюдателей.
    var status: ObservingStatus {
        if activeObserverCount > 0 {
            return .active
        } else if observerCount > 0 {
            return .inactive
        } else {
            return .none
        }
    }

    init(
        observerIds: Set<UUID> = [],
        activeObserverIds: Set<UUID> = [],
        observingTime: ObservingTime = .never
    ) {
        self.observerIds = observerIds
        self.activeObserverIds = activeObserverIds
        self.observingTime = observingTime
    }
}

/// Представляет статус наблюдателей для реплики.
/// - none - нет наблюдателей
/// - inactive - eсть неактивные наблюдатели
/// - active - eсть активные наблюдатели
enum ObservingStatus {
    case none
    case inactive
    case active
}

/// Представляет время последнего наблюдения за репликой.
/// - never - никогда не наблюдалась
/// - timeInPast -  время в прошлом
/// - now - сейчас наблюдается
enum ObservingTime: Comparable {
    case never
    case timeInPast(Date)
    case now

    // MARK: - Comparable

    /// Сравнение двух значений ObservingTime.
    static func < (lhs: ObservingTime, rhs: ObservingTime) -> Bool {
        switch (lhs, rhs) {
        case (.never, .never):
            return false
        case (.never, _):
            return true
        case (_, .never):
            return false
        case (.timeInPast(let lhsTime), .timeInPast(let rhsTime)):
            return lhsTime < rhsTime
        case (.timeInPast, .now):
            return true
        case (.now, .timeInPast):
            return false
        case (.now, .now):
            return false
        }
    }

    /// Проверка равенства двух значений ObservingTime.
    static func == (lhs: ObservingTime, rhs: ObservingTime) -> Bool {
        switch (lhs, rhs) {
        case (.never, .never), (.now, .now):
            return true
        case (.timeInPast(let lhsTime), .timeInPast(let rhsTime)):
            return lhsTime == rhsTime
        default:
            return false
        }
    }
}
