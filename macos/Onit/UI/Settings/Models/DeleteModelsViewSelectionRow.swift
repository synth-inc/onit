//
//  DeleteModelsViewSelectionRow.swift
//  Onit
//
//  Created by Loyd KIm on 4/9/25.
//

import SwiftUI

struct DeleteModelsViewSelectionRow: View {
    @Environment(\.model) var model
    
    let aiModel: AIModel
    
    var body: some View {
        HStack (spacing: 0) {
            Toggle(
                "",
                isOn: .init(
                    get: { model.modelIdsSelectedForDeletion.contains(aiModel.uniqueId) },
                    set: { isSelectedForDeletion in
                        if isSelectedForDeletion {
                            model.modelIdsSelectedForDeletion.insert(aiModel.uniqueId)
                        } else {
                            model.modelIdsSelectedForDeletion.remove(aiModel.uniqueId)
                        }
                    }
            ))
            .toggleStyle(.checkbox)
            
            Text(aiModel.displayName).font(.system(size: 13))
        }
    }
}
