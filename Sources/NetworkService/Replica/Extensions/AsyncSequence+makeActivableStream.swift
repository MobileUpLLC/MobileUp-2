extension AsyncSequence {
    /// Преобразует исходный поток в поток, который активируется или деактивируется на основе другого потока активности.
    internal func makeActivableStream<T: Sendable>(
        source: AsyncStream<T>,
        activeStream: AsyncStream<Bool>
    ) -> AsyncStream<T> {
        return AsyncStream { continuation in
            let controller = StreamManager(continuation: continuation)

            _Concurrency.Task {
                await controller.start(source: source, activeStream: activeStream)
            }

            continuation.onTermination = { _ in
                _Concurrency.Task {
                    await controller.cancel()
                }
            }
        }
    }
}

/// Внутренний actor для управления задачей и потокобезопасности.
private actor StreamManager<T: Sendable> {
    private var task: _Concurrency.Task<Void, Never>?
    private let continuation: AsyncStream<T>.Continuation

    init(continuation: AsyncStream<T>.Continuation) {
        self.continuation = continuation
    }

    /// Запускает управление потоком на основе активности.
    func start(source: AsyncStream<T>, activeStream: AsyncStream<Bool>) {
        task = _Concurrency.Task {
            for await isActive in activeStream {
                if isActive {
                    for await value in source {
                        continuation.yield(value)
                    }
                }
            }
            continuation.finish()
        }
    }

    /// Отменяет текущую задачу.
    func cancel() {
        task?.cancel()
        task = nil
        continuation.finish()
    }
}
