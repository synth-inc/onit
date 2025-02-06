//
//  DropItem.swift
//  Onit
//
//  Created by Benjamin Sage on 1/15/25.
//

import SwiftUI
import UniformTypeIdentifiers

enum DropItem: Transferable {
  case url(URL)
  case image(NSImage)

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { DropItem.url($0) }
    ProxyRepresentation { DropItem.image($0) }
  }

  var url: URL? {
    switch self {
    case .url(let url): return url
    default: return nil
    }
  }

  var image: NSImage? {
    switch self {
    case .image(let image): return image
    default: return nil
    }
  }
}
