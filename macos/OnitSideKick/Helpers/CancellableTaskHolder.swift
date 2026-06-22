//
//  CancellableTaskHolder.swift
//  Onit
//
//  Created by Kévin Naudin on 10/24/2025.
//

import Foundation

/// Holds a single DispatchWorkItem and cancels the previous one on replace.
final class CancellableTaskHolder {
    private var task: DispatchWorkItem?

    func replace(with newTask: DispatchWorkItem?) {
        task?.cancel()
        task = newTask
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }
}
