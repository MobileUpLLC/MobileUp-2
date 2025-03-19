import Foundation

/// Данные, хранимые в реплике.
struct ReplicaData<T> {
    let value: T
    let isFresh: Bool
    let changingDate: Date
    let optimisticUpdates: [OptimisticUpdate<T>]

    /// Значение с применёнными оптимистичными обновлениями.
    var valueWithOptimisticUpdates: T {
        optimisticUpdates.applyAll(to: value)
    }

    init(
        value: T,
        isFresh: Bool,
        changingDate: Date,
        optimisticUpdates: [OptimisticUpdate<T>] = []
    ) {
        self.value = value
        self.isFresh = isFresh
        self.changingDate = changingDate
        self.optimisticUpdates = optimisticUpdates
    }
}
