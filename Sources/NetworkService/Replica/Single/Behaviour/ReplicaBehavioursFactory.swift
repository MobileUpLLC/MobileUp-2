import Foundation

struct ReplicaBehavioursFactory<T: AnyObject & Sendable> {
    static func createBehavioursForReplicaSettings(
        settings: ReplicaSettings,
        networkConnectivityProvider: (any NetworkConnectivityProvider)?
    ) -> [any ReplicaBehaviour] {
        var behaviours: [any ReplicaBehaviour] = []

        if let staleTime = settings.staleTime {
            behaviours.append(StaleAfterGivenTime<T>(timeInterval: staleTime))
        }

        if let clearTime = settings.clearTime {
            behaviours.append(createClearingBehaviour(clearTime: clearTime))
        }

        if let clearErrorTime = settings.clearErrorTime {
            behaviours.append(createErrorClearingBehaviour(clearErrorTime: clearErrorTime))
        }

        if let cancelTime = settings.cancelTime {
            behaviours.append(createCancellationBehaviour(cancelTime: cancelTime))
        }

        if settings.isNeedToRefreshOnActiveObserverAdded {
            behaviours.append(createRevalidationOnActiveObserverAddedBehaviour())
        }

        if let provider = networkConnectivityProvider, settings.isNeedToRefreshOnNetworkConnection {
            behaviours.append(createRevalidationOnNetworkConnectionBehaviour(provider: provider))
        }

        return behaviours
    }

    private static func createClearingBehaviour(clearTime: TimeInterval) -> any ReplicaBehaviour {
        DoOnStateCondition<Sendable & AnyObject>(
            condition: { state in
                (state.data != nil || state.error != nil) && !state.loading &&
                state.observingState.status == .none
            },
            startDelay: clearTime,
            action: { replica in
                try await replica.clear(removeFromStorage: true)
            }
        )
    }

    private static func createErrorClearingBehaviour(clearErrorTime: TimeInterval) -> any ReplicaBehaviour {
        DoOnStateCondition<Sendable & AnyObject>(
            condition: { state in
                state.error != nil && !state.loading &&
                state.observingState.status == .none
            },
            startDelay: clearErrorTime,
            action: { replica in
                try await replica.clearError()
            }
        )
    }

    private static func createCancellationBehaviour(cancelTime: TimeInterval) -> any ReplicaBehaviour {
        DoOnStateCondition<Sendable & AnyObject>(
            condition: { state in
                state.loading && !state.dataRequested && !state.preloading &&
                state.observingState.status == .none
            },
            startDelay: cancelTime,
            action: { replica in
                replica.cancel()
            }
        )
    }

    private static func createRevalidationOnActiveObserverAddedBehaviour() -> any ReplicaBehaviour {
        DoOnEvent<Sendable & AnyObject> { replica, event   in
            switch event {
            case .observerCountChanged(let observerEvent):
                if observerEvent.activeCount > observerEvent.previousActiveCount {
                    replica.revalidate()
                }
            default:
                break
            }
        }
    }

    static func createRevalidationOnNetworkConnectionBehaviour(
        provider: any NetworkConnectivityProvider
    ) -> any ReplicaBehaviour<T> {
        DoOnNetworkConnectivityChanged(
            networkConnectivityProvider: provider,
            action: { replica, connected in
                let state = await replica.currentState
                if connected && state.observingState.status == .active {
                    replica.revalidate()
                }
            }
        )
    }
}
