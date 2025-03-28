//
//  DropItem.swift
//  Onit
//
//  Created by Benjamin Sage on 1/15/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum DropItem: Transferable {
    case data(Data)
    case url(URL)
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: UTType.image) { image in
            image.data!
        } importing: { data in
            return DropItem.data(data)
        }
        ProxyRepresentation { return DropItem.url($0) }
    }

    var url: URL? {
        switch self {
        case .url(let url): return url
        default: return nil
        }
    }

   var data: Data? {
       switch self {
       case .data(let data): return data
       default: return nil
       }
   }
}
