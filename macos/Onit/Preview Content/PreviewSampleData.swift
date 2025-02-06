//
//  PreviewSampleData.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftData

actor PreviewSampleData {
  @MainActor
  static var container: ModelContainer = {
    try! inMemoryContainer()
  }()

  @MainActor
  static var remoteModels: RemoteModelsState = {
    RemoteModelsState()
  }()

  @MainActor
  static var customProvider: CustomProvider = {
    CustomProvider(
      name: "Provider name", baseURL: "http://google.com", token: "aiZafeoi", models: [])
  }()

  @MainActor
  static var inMemoryContainer: () throws -> ModelContainer = {
    let schema = Schema([Prompt.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let sampleData: [any PersistentModel] = [
      Prompt.sample
    ]
    sampleData.forEach {
      container.mainContext.insert($0)
    }
    return container
  }
}
