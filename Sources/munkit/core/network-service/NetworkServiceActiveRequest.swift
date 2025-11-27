//
//  NetworkServiceActiveRequest.swift
//  MUNKit
//
//  Created by Ilia Chub on 21.04.2025.
//

import Foundation

struct NetworkServiceActiveRequest: Hashable {
    struct AnyTask {
        private let _cancel: () -> Void
        
        init<T>(_ task: Task<T, Error>) {
            _cancel = { task.cancel() }
        }
        
        func cancel() {
            _cancel()
        }
    }
    
    let id: UUID
    let isAccessTokenRequired: Bool
    let task: AnyTask
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isAccessTokenRequired)
    }
}
