//
//  DiffView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import SwiftUI

struct DiffView: View {
    @Binding var oldText: String
    @Binding var newText: String
    @Binding var isStreaming: Bool
    
    struct Diff: Hashable {
        let id: UUID
        let char: Character
        let line: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Diff, rhs: Diff) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(computeDiff(), id: \.id) { diff in
                    HStack(alignment: .top, spacing: 0) {
                        Text("\(diff.char)")
                            .frame(width: 30, alignment: .center)
                        Text(diff.line)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundColor(colorFor(character: diff.char))
                    .background(backgroundFor(character: diff.char))
                    .font(.custom("Inter-Medium", size: 14))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func computeDiff() -> [Diff] {
        var oldLines = oldText.split(separator: "\n").map(String.init)
        let newLines = newText.split(separator: "\n").map(String.init)
        
        if isStreaming {
            oldLines = Array(oldLines.prefix(newLines.count))
        }

        var result: [Diff] = []
        var oldIndex = 0
        var newIndex = 0
        
        while oldIndex < oldLines.count || newIndex < newLines.count {
            if oldIndex < oldLines.count && newIndex < newLines.count {
                if oldLines[oldIndex] == newLines[newIndex] {
                    result.append(Diff(id: UUID(), char: " ", line: oldLines[oldIndex]))
                    oldIndex += 1
                    newIndex += 1
                } else {
                    result.append(Diff(id: UUID(), char: "-", line: oldLines[oldIndex]))
                    result.append(Diff(id: UUID(), char: "+", line: newLines[newIndex]))
                    oldIndex += 1
                    newIndex += 1
                }
            } else if oldIndex < oldLines.count {
                result.append(Diff(id: UUID(), char: "-", line: oldLines[oldIndex]))
                oldIndex += 1
            } else if newIndex < newLines.count {
                result.append(Diff(id: UUID(), char: "+", line: newLines[newIndex]))
                newIndex += 1
            }
        }
        
        return result
    }
    
    private func colorFor(character: Character) -> Color {
        switch character {
        case "+": return .limeGreen
        case "-": return .diffRed
        default: return .white
        }
    }
    
    private func backgroundFor(character: Character) -> some View {
        Group {
            switch character {
            case "+": Rectangle().fill(.diffBgGreen)
            case "-": Rectangle().fill(.diffBgRed)
            default: EmptyView()
            }
        }
    }
}

#Preview {
    DiffView(
        oldText: .constant("""
            Bonjour
            Ceci est un test
            Une ligne supprimée
            """),
        newText: .constant("""
            Bonjour
            Ceci est un test modifié
            Une ligne ajoutée
            """),
        isStreaming: .constant(true))
}
