//
//  File 2.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 19.03.2025.
//

import Foundation

actor ObserversController<T: AnyObject & Sendable> {
    private let timeProvider: any TimeProvider
    private let dispatcher: DispatchQueue // Оставлен для совместимости, но не обязателен
    private var replicaState: ReplicaState<T>
    private var eventContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?

    // Предоставляем доступ к состоянию через метод
    func currentState() -> ReplicaState<T> {
        replicaState
    }

    // Предоставляем поток событий
    func eventFlow() async -> AsyncStream<ReplicaEvent<T>> {
        AsyncStream { continuation in
            self.eventContinuation = continuation
        }
    }

    init(
        timeProvider: any TimeProvider,
        dispatcher: DispatchQueue,
        initialState: ReplicaState<T>
    ) {
        self.timeProvider = timeProvider
        self.dispatcher = dispatcher
        self.replicaState = initialState
    }
    
    func onObserverAdded(observerId: Int64, active: Bool) async {
        let state = replicaState
        let observingState = state.observingState
        
        let newActiveObserverIds = active ? observingState.activeObserverIds.union([observerId]) : observingState.activeObserverIds
        let newObservingTime = active ? ObservingTime.now : observingState.observingTime
        
        replicaState = state.copy(
            observingState: ObservingState(
                observerIds: observingState.observerIds.union([observerId]),
                activeObserverIds: newActiveObserverIds,
                observingTime: newObservingTime
            )
        )
        
        await emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }
    
    func onObserverRemoved(observerId: Int64) async {
        let state = replicaState
        let observingState = state.observingState
        
        let lastActiveObserver = observingState.activeObserverIds.count == 1 && observingState.activeObserverIds.contains(observerId)
        let newObservingTime = lastActiveObserver ? ObservingTime.timeInPast(timeProvider.currentTime()) : observingState.observingTime
        
        replicaState = state.copy(
            observingState: ObservingState(
                observerIds: observingState.observerIds.subtracting([observerId]),
                activeObserverIds: observingState.activeObserverIds.subtracting([observerId]),
                observingTime: newObservingTime
            )
        )
        
        await emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }
    
    func onObserverActive(observerId: Int64) async {
        let state = replicaState
        let observingState = state.observingState
        
        replicaState = state.copy(
            observingState: ObservingState(
                observerIds: observingState.observerIds,
                activeObserverIds: observingState.activeObserverIds.union([observerId]),
                observingTime: ObservingTime.now
            )
        )
        
        await emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }
    
    func onObserverInactive(observerId: Int64) async {
        let state = replicaState
        let observingState = state.observingState
        
        let lastActiveObserver = observingState.activeObserverIds.count == 1 && observingState.activeObserverIds.contains(observerId)
        let newObservingTime = lastActiveObserver ? ObservingTime.timeInPast(timeProvider.currentTime()) : observingState.observingTime

        replicaState = state.copy(
            observingState: ObservingState(
                observerIds: observingState.observerIds,
                activeObserverIds: observingState.activeObserverIds.subtracting([observerId]),
                observingTime: newObservingTime
            )
        )

        await emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }

    private func emitObserverCountChangedEventIfRequired(
        previousObservingState: ObservingState,
        newObservingState: ObservingState
    ) async {
        if previousObservingState.observerCount != newObservingState.observerCount ||
           previousObservingState.activeObserverCount != newObservingState.activeObserverCount {
            eventContinuation?.yield(
                .observerCountChanged(
                    ObserversCountInfo(
                        count: newObservingState.observerCount,
                        activeCount: newObservingState.activeObserverCount,
                        previousCount: previousObservingState.observerCount,
                        previousActiveCount: previousObservingState.activeObserverCount
                    )
                )
            )
        }
    }
}
