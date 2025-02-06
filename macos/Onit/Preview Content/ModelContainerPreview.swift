//
//  ModelContainerPreview.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftData
import SwiftUI

struct ModelContainerPreview<Content: View>: View {
  var content: () -> Content
  let container: ModelContainer
  @State var model: OnitModel

  init(
    _ modelContainer: @escaping () throws -> ModelContainer = PreviewSampleData.inMemoryContainer,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.content = content
    do {
      self.container = try MainActor.assumeIsolated(modelContainer)
      let model = OnitModel(container: self.container, remoteModels: PreviewSampleData.remoteModels)
      self._model = State(initialValue: model)
    } catch {
      fatalError("Failed to create the model container: \(error.localizedDescription)")
    }
  }

  var body: some View {
    content()
      .environment(model)
      .modelContainer(container)
  }
}
