//
//  Loader.swift
//  Onit
//
//  Created by Loyd Kim on 4/17/25.
//

import SwiftUI

struct Loader: View {
    private let size: CGFloat
    private let scaleEffect: Double
    private let controlSize: ControlSize
    
    init(
        size: CGFloat = 16,
        scaleEffect: Double = 0.5,
        controlSize: ControlSize = ControlSize.regular
    ) {
        self.size = size
        self.scaleEffect = scaleEffect
        self.controlSize = controlSize
    }
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .frame(width: size, height: size)
            .controlSize(controlSize)
            .scaleEffect(scaleEffect)
            .fixedSize()
    }
}
