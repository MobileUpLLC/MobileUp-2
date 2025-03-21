import Foundation

protocol AccessTokenProvider {
    var accessToken: String? { get }
}

struct AccessTokenPlugin: PluginType {
    private let accessTokenProvider: AccessTokenProvider
    
    init(accessTokenProvider: AccessTokenProvider) {
        self.accessTokenProvider = accessTokenProvider
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let mobileApiTarget = target as? MobileApiTargetType else {
            return request
        }
        
        return prepare(request, target: mobileApiTarget)
    }

    private func prepare(_ request: URLRequest, target: MobileApiTargetType) -> URLRequest {
        var request = request
        
        if target.isAccessTokenRequired, let accessToken = accessTokenProvider.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
