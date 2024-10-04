//
//  FetchingClient+Config.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

extension FetchingClient {
    struct FetchingConfig {
        let validStatuses: Set<Int>
        let logoutStatus: Int
        let forbiddenStatus: Int
        let notFoundStatus: Int
    }

    var config: FetchingConfig {
        FetchingConfig(
            validStatuses: [200, 201, 204],
            logoutStatus: 401,
            forbiddenStatus: 403,
            notFoundStatus: 404
        )
    }
}
