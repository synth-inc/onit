//
//  UploadBody.swift
//  Onit
//
//  Created by Benjamin Sage on 10/29/24.
//

import Foundation

enum UploadBody {
    case data(Data)
    case url(URL)
    case empty
}
