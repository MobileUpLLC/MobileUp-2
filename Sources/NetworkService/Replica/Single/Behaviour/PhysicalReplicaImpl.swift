import Foundation

actor PhysicalReplicaImpl<T: AnyObject & Sendable>: PhysicalReplica {
    
    var eventFlow: AsyncStream<ReplicaEvent<T>>

    let id = UUID()
    let name: String
    let settings: ReplicaSettings
    let tags: Set<ReplicaTag>
    
    private let timeProvider: any TimeProvider
    private let behaviours: [any ReplicaBehaviour<T>]
    private let storage: (any Storage<T>)?
    private let fetcher: any Fetcher<T>
    
    private var stateContinuation: AsyncStream<ReplicaState<T>>.Continuation?
    private var eventContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?
    
    var stateFlow: AsyncStream<ReplicaState<T>> {
        get async {
            AsyncStream { continuation in
                self.stateContinuation = continuation
                continuation.yield(ReplicaState.createEmpty(hasStorage: storage != nil))
            }
        }
    }
    
    var eventFlow: AsyncStream<ReplicaEvent<T>> {
        get async {
            AsyncStream { continuation in
                self.eventContinuation = continuation
            }
        }
    }
    
    private let observersController: ObserversController<T>
    private let dataLoadingController: DataLoadingController<T>
    private let dataChangingController: DataChangingController<T>
    private let freshnessController: FreshnessController<T>
    private let clearingController: ClearingController<T>
    private let optimisticUpdatesController: OptimisticUpdatesController<T>
    
    init(
        timeProvider: any TimeProvider,
        dispatcher: DispatchQueue,
        name: String,
        settings: ReplicaSettings,
        tags: Set<ReplicaTag>,
        behaviours: [any ReplicaBehaviour<T>],
        storage: (any Storage<T>)?,
        fetcher: any Fetcher<T>
    ) {
        self.timeProvider = timeProvider
        self.name = name
        self.settings = settings
        self.tags = tags
        self.behaviours = behaviours
        self.storage = storage
        self.fetcher = fetcher
        
        self.observersController = ObserversController()
        self.dataLoadingController = DataLoadingController()
        self.dataChangingController = DataChangingController()
        self.freshnessController = FreshnessController()
        self.clearingController = ClearingController()
        self.optimisticUpdatesController = OptimisticUpdatesController()
        
        _Concurrency.Task { @Sendable [weak self] in
            guard let self else {
                return
            }
            for behaviour in behaviours {
                await behaviour.setup(replica: self)
            }
        }
    }
    
    func observe(observerHost: any ReplicaObserverHost) async -> any ReplicaObserver<T> {
        ReplicaObserverImpl(
            observerHost: observerHost,
            replicaStateFlow: await stateFlow,
            replicaEventFlow: await eventFlow,
            observersController: observersController
        )
    }
    
    func refresh() async {
        await dataLoadingController.refresh()
    }
    
    func revalidate() async {
        await dataLoadingController.revalidate()
    }
    
    func getData(forceRefresh: Bool) async throws -> T {
        try await dataLoadingController.getData(forceRefresh: forceRefresh)
    }
    
    func setData(_ data: T) async {
        await dataChangingController.setData(data: data)
    }
    
    func mutateData(_ transform: @Sendable (T) -> T) async {
        await dataChangingController.mutateData(transform: transform)
    }
    
    func invalidate(mode: InvalidationMode) async {
        await freshnessController.invalidate()
        await dataLoadingController.refreshAfterInvalidation(mode)
    }
    
    func makeFresh() async {
        await freshnessController.makeFresh()
    }
    
    func cancel() async {
        await dataLoadingController.cancel()
    }

    func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async {
        await dataLoadingController.cancel()
        await clearingController.clear(removeFromStorage: removeFromStorage)
        await dataLoadingController.refreshAfterInvalidation(invalidationMode)
    }
    
    func clearError() async {
        await clearingController.clearError()
    }
    
    func beginOptimisticUpdate(_ update: OptimisticUpdate<T>) async {
        await optimisticUpdatesController.beginOptimisticUpdate(update: update)
    }
    
    func commitOptimisticUpdate(_ update: OptimisticUpdate<T>) async {
        await optimisticUpdatesController.commitOptimisticUpdate(update: update)
    }
    
    func rollbackOptimisticUpdate(_ update: OptimisticUpdate<T>) async {
        await optimisticUpdatesController.rollbackOptimisticUpdate(update: update)
    }
}
