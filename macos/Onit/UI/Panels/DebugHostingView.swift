import SwiftUI

class DebugHostingView<Content: View>: NSHostingView<Content> {
    
    override func layout() {
        super.layout()
        print("Auto Layout: layout() called on DebugHostingView, frame: \(frame)")
        printConstraints()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        print("Auto Layout: updateConstraints() called on DebugHostingView, frame: \(frame)")
        printConstraints()
    }

    override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        print("Intrinsic content size: \(size)")
        return size
    }
       
    override var frame: NSRect {
        didSet {
            // Optionally, print out constraints whenever the frame changes.
            print("Auto Layout: frame updated to \(frame)")
            if frame.size.height == 1729.0 {
                print("setting to too tall")
            }
            printConstraints()
        }
    }
    
    private func printConstraints() {
        // print("=== DebugHostingView Constraints ===")
//         for constraint in constraints {
//             print(constraint)
//         }
        // if let superConstraints = superview?.constraints {
        //     print("--- Superview Constraints ---")
        //     for constraint in superConstraints {
        //         print(constraint)
        //     }
        // }
        // print("====================================")
    }
}
