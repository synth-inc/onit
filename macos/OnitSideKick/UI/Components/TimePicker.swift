//
//  TimePicker.swift
//  Onit
//
//  Created by Loyd Kim on 9/10/25.
//

import AppKit
import SwiftUI

struct TimePicker: View {
    // MARK: - Properties
    
    @Binding private var time: Date
    
    init(time: Binding<Date>) {
        self._time = time
    }
    
    // MARK: - Body
    
    var body: some View {
        NSTimePicker(date: self.$time)
            .padding([.vertical, .leading], 2)
            .padding(.trailing, 4)
            .addBorder(
                cornerRadius: 6,
                stroke: Color.S_0.opacity(0.1)
            )
    }
    
    // MARK: - Child Components
    
    private struct NSTimePicker: NSViewRepresentable {
        typealias NSViewType = NSDatePicker
        
        @Binding var date: Date
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeNSView(context: NSViewRepresentableContext<NSTimePicker>) -> NSDatePicker {
            let picker = NSDatePicker()
            
            /// Time configs
            picker.locale = .current
            picker.timeZone = .current
            picker.datePickerStyle = .textFieldAndStepper
            picker.datePickerElements = .hourMinute
            picker.datePickerMode = .single
            picker.dateValue = date
            
            /// Size configs
            picker.controlSize = .small
            picker.setContentHuggingPriority(.required, for: .horizontal)
            picker.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            /// Styling configs
            picker.isBordered = false
            picker.isBezeled = false
            picker.drawsBackground = false
            
            picker.backgroundColor = NSColor.clear
            picker.font = .systemFont(ofSize: 14, weight: .regular)
            
            picker.target = context.coordinator
            picker.action = #selector(Coordinator.changed(_:))
            
            return picker
        }
        
        func updateNSView(
            _ view: NSDatePicker,
            context: NSViewRepresentableContext<NSTimePicker>
        ) {
            if view.dateValue != date {
                view.dateValue = date
            }
        }

        final class Coordinator: NSObject {
            var parent: NSTimePicker
            
            init(_ parent: NSTimePicker) {
                self.parent = parent
            }
            
            @MainActor
            @objc func changed(_ sender: NSDatePicker) {
                parent.date = sender.dateValue
            }
        }
    }
}
