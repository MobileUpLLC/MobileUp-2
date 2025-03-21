import Alamofire
import Foundation

public struct ErrorDetails: Sendable {
    public var statusCode: Int?
    public var message = ""
    public var error: Error?

    public init(statusCode: Int? = nil, message: String = "", error: Error? = nil) {
        self.statusCode = statusCode
        self.message = message
        self.error = error
    }
}

public enum ServerError: Error {
    /// statusCode: 400
    case badRequest(details: ErrorDetails)
    /// statusCode: 401
    case unauthorized(details: ErrorDetails)
    /// statusCode: 403
    case forbidden(details: ErrorDetails)
    /// statusCode: 404
    case notFound(details: ErrorDetails)
    /// statusCode: 409
    case tokenExpired(details: ErrorDetails)
    /// statusCode: 500
    case internalServerError(details: ErrorDetails)
    /// statusCode: 502
    case badGateway(details: ErrorDetails)
    /// statusCode: 503
    case serviceUnavailable(details: ErrorDetails)
    /// statusCode: 504
    case gatewayTimeOut(details: ErrorDetails)
    case networkError(details: ErrorDetails)
    case unknown(details: ErrorDetails)
    case systemError(details: ErrorDetails)
    case swiftError(details: ErrorDetails)
    
    public var details: ErrorDetails {
        switch self {
        case let .badRequest(details):
            return details
        case let .unauthorized(details):
            return details
        case let .forbidden(details):
            return details
        case let .notFound(details):
            return details
        case let .tokenExpired(details):
            return details
        case let .badGateway(details):
            return details
        case let .internalServerError(details):
            return details
        case let .serviceUnavailable(details):
            return details
        case let .gatewayTimeOut(details):
            return details
        case let .unknown(details):
            return details
        case let .networkError(details):
            return details
        case let .systemError(details):
            return details
        case let .swiftError(details):
            return details
        }
    }
    
    public var title: String {
        let defaultTitle = "Ошибка"
        var detailsTitle = ""
        
        switch self {
        case .networkError:
            detailsTitle = "Нет подключения к интернету"
        default:
            break
        }
        
        return detailsTitle.isEmpty == false ? detailsTitle : defaultTitle
    }
    
    public static func handleError(_ error: Error, response: Response) -> ServerError {
        let responseCode = response.statusCode
        
        var errorDetails = ErrorDetails()
        errorDetails.statusCode = responseCode
        
        let serverError: ServerError
        
        switch responseCode {
        case 200:
            errorDetails.message = "Decoding Error"
            errorDetails.error = error
            serverError = .systemError(details: errorDetails)
        case 400:
            serverError = .badRequest(details: errorDetails)
        case 401:
            serverError = .unauthorized(details: errorDetails)
        case 403:
            serverError = .forbidden(details: errorDetails)
        case 404:
            serverError = .notFound(details: errorDetails)
        case 500:
            serverError = .internalServerError(details: errorDetails)
        case 502:
            serverError = .badGateway(details: errorDetails)
        case 503:
            serverError = .serviceUnavailable(details: errorDetails)
        case 504:
            errorDetails.message = "Gateway Time-out"
            errorDetails.error = error
            serverError = .gatewayTimeOut(details: errorDetails)
        default:
            errorDetails.error = error
            serverError = .unknown(details: errorDetails)
        }
        
        return serverError
    }

    public static func mapError(_ error: MoyaError) -> ServerError {
        var details = ErrorDetails(error: error)

        if
            case let .underlying(error, _) = error,
            let errorCode = error.asAFError?.getErrorCode(),
            isNetworkErrorCode(errorCode)
        {
            details.message = "Пожалуйста проверьте настройки сети и попробуйте снова"
            return .networkError(details: details)
        }

        return .swiftError(details: details)
    }

    private static func isNetworkErrorCode(_ errorCode: Int) -> Bool {
        let isNetworkErrorCode = errorCode == NSURLErrorNotConnectedToInternet ||
        errorCode == NSURLErrorNetworkConnectionLost ||
        errorCode == NSURLErrorDataNotAllowed

        return isNetworkErrorCode
    }
}

private extension AFError {
   func getErrorCode() -> Int? {
       if case .sessionTaskFailed(let sessionTaskError) = self {
           return (sessionTaskError as NSError).code
       }

       return responseCode
   }
}
