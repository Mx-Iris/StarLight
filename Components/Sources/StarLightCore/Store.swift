//
//  Store.swift
//  StarLight
//
//  Created by JH on 2024/12/29.
//

import Foundation
import GitHubModels
import GitHubNetworking

final class Store {

    
    private(set) var repositories: [Repository] = []
    
    private var client: GitHubClient?
    
    init() {
        
    }
}
