//
//  ScrollPassthroughWebView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/03/2025.
//

import WebKit

class ScrollPassthroughWebView: WKWebView {
    override func scrollWheel(with event: NSEvent) {
        // Ne pas traiter l'événement de défilement, le laisser remonter à la vue parente
        nextResponder?.scrollWheel(with: event)
    }
}
