import Foundation

extension MoyaProvider {
    func request<T: Decodable & Sendable>(target: Target) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            request(target) { [weak self] result in
                switch result {
                case .success(let response):
                    self?.handleRequestSuccess(response: response, continuation: continuation)
                case .failure(let error):
                    self?.handleRequestFailure(error: error, continuation: continuation)
                }
            }
        }
    }
    
    func request(target: Target) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            request(target) { [weak self] result in
                switch result {
                case .success(let response):
                    self?.handleRequestSuccess(response: response, continuation: continuation)
                case .failure(let error):
                    self?.handleRequestFailure(error: error, continuation: continuation)
                }
            }
        }
    }
    
    private func handleRequestSuccess<T: Decodable & Sendable>(response: Response, continuation: CheckedContinuation<T, Error>) {
        do {
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let decodedResponse = try filteredResponse.map(T.self)
            
            continuation.resume(returning: decodedResponse)
        } catch let error {
            let serverError = ServerError.handleError(error, response: response)
            
            continuation.resume(throwing: serverError)
        }
    }
    
    private func handleRequestSuccess(response: Response, continuation: CheckedContinuation<Void, Error>) {
        do {
            _ = try response.filterSuccessfulStatusCodes()
            continuation.resume()
        } catch let error {
            let serverError = ServerError.handleError(error, response: response)
            continuation.resume(throwing: serverError)
        }
    }
    
    private func handleRequestFailure<T: Decodable>(error: MoyaError, continuation: CheckedContinuation<T, Error>) {
        let mappedError = ServerError.mapError(error)
        continuation.resume(throwing: mappedError)
    }
    
    private func handleRequestFailure(error: MoyaError, continuation: CheckedContinuation<Void, Error>) {
        let mappedError = ServerError.mapError(error)
        continuation.resume(throwing: mappedError)
    }
}
