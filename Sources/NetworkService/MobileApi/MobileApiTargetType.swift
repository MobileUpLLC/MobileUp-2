import Foundation

public protocol MobileApiTargetType: TargetType, AccessTokenAuthorizable {
    var parameters: [String: Any] { get }
    var isAccessTokenRequired: Bool { get }
    var isRefreshTokenRequest: Bool { get }
}
