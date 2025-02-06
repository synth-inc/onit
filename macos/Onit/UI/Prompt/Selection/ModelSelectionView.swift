//
//  ModelSelectionView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct ModelSelectionView: View {
  @Environment(\.model) var model
  @Environment(\.openSettings) var openSettings
  @Environment(\.remoteModels) var remoteModels

  @Default(.mode) var mode
  @Default(.localModel) var localModel
  @Default(.remoteModel) var remoteModel
  @Default(.useOpenAI) var useOpenAI
  @Default(.useAnthropic) var useAnthropic
  @Default(.useXAI) var useXAI
  @Default(.useGoogleAI) var useGoogleAI
  @Default(.availableRemoteModels) var availableRemoteModels
  @Default(.availableLocalModels) var availableLocalModels

  var selectedModel: Binding<SelectedModel?> {
    .init {
      if mode == .local, let localModelName = localModel {
        return .local(localModelName)
      } else if let aiModel = remoteModel {
        return .remote(aiModel)
      } else {
        return nil
      }
    } set: { newValue in
      guard let newValue else { return }
      switch newValue {
      case .remote(let aiModel):
        remoteModel = aiModel
        mode = .remote
      case .local(let localModelName):
        localModel = localModelName
        mode = .local
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      remote
      divider
      local
      divider
      advanced
    }
    .foregroundStyle(.FG)
    .padding(.vertical, 12)
    .background(.gray600, in: .rect(cornerRadius: 12))
    .frame(minWidth: 218, alignment: .leading)
    .overlay(alignment: .topTrailing) {
      Button(action: {
        model.closeModelSelectionOverlay()
      }) {
        Image(.smallRemove)
          .renderingMode(.template)
          .foregroundStyle(.gray200)
      }
      .padding(8)
      .buttonStyle(PlainButtonStyle())
    }
  }

  var remote: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text("Remote models")
          .appFont(.medium13)
          .foregroundStyle(.white.opacity(0.6))
        Spacer()
        if remoteModels.remoteNeedsSetup
          || (!remoteModels.remoteNeedsSetup && availableRemoteModels.isEmpty)
        {
          Image(.warningSettings)
        }
      }
      .padding(.horizontal, 12)

      if remoteModels.listedModels.isEmpty {
        Button("Setup remote models") {
          model.settingsTab = .models
          openSettings()
        }
        .buttonStyle(SetUpButtonStyle(showArrow: true))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)

      } else {
        remoteModelsView
      }
    }
  }

  var custom: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text("Custom models")
          .appFont(.medium13)
          .foregroundStyle(.white.opacity(0.6))
        Spacer()
        if remoteModels.remoteNeedsSetup
          || (!remoteModels.remoteNeedsSetup && availableRemoteModels.isEmpty)
        {
          Image(.warningSettings)
        }
      }
      .padding(.horizontal, 12)

      if remoteModels.listedModels.isEmpty {
        Button("Setup remote models") {
          model.settingsTab = .models
          openSettings()
        }
        .buttonStyle(SetUpButtonStyle(showArrow: true))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)

      } else {
        remoteModelsView
      }
    }
  }

  var remoteModelsView: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Picker("", selection: selectedModel) {
          ForEach(remoteModels.listedModels) { model in
            Text(model.displayName)
              .appFont(.medium14)
              .tag(SelectedModel.remote(model))
              .padding(.vertical, 4)
          }
        }
        .pickerStyle(.inline)
        .clipped()
        .padding(.vertical, 4)
        .padding(.bottom, 5)
        .padding(.leading, 5)
        .tint(.blue600)
      }
    }
    .frame(maxHeight: 300)
  }

  var divider: some View {
    Color.gray400
      .frame(height: 1)
  }

  var local: some View {
    VStack(spacing: 2) {
      HStack(spacing: 4) {
        Text("Local models")
          .foregroundStyle(.FG.opacity(0.6))
          .appFont(.medium13)
        if availableLocalModels.isEmpty {
          Image(.warningSettings)
        }
        Spacer()
        add
      }
      .padding(.horizontal, 12)

      if availableLocalModels.isEmpty {
        Button("Setup local models") {
          model.settingsTab = .models
          openSettings()
        }
        .buttonStyle(SetUpButtonStyle(showArrow: true))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 10)

      } else {
        localModelsView
      }
    }
    .padding(.top, 8)
    .padding(.bottom, 4)
  }

  var localModelsView: some View {
    Picker("", selection: selectedModel) {
      ForEach(availableLocalModels, id: \.self) { localModelName in
        Text(localModelName)
          .appFont(.medium14)
          .tag(SelectedModel.local(localModelName))
          .padding(.vertical, 4)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .pickerStyle(.inline)
    .padding(.vertical, 4)
    .padding(.bottom, 5)
    .padding(.leading, 5)
    .tint(.blue600)
  }

  var add: some View {
    HStack(spacing: 4) {
      Text("Add")
        .appFont(.medium13)
      Image(.plus)
    }
    .padding(.vertical, 2)
    .padding(.leading, 4)
    .padding(.trailing, 4)
    .background(.gray400, in: .rect(cornerRadius: 5))
    .opacity(0.3)
  }

  var advanced: some View {
    Button {
      NSApp.activate()
      if NSApp.isActive {
        model.setSettingsTab(tab: .models)
        openSettings()
        model.closeModelSelectionOverlay()
      }
    } label: {
      HStack {
        Text("Advanced settings")
        Spacer()
        Image(.chevRight)
      }
      .padding(6)
      .contentShape(.rect)
    }
    .padding(.horizontal, 6)
    .padding(.top, 6)
    .buttonStyle(AdvancedSettingsButtonStyle())
  }
}

struct AdvancedSettingsButtonStyle: ButtonStyle {
  @State private var hovering = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(Color.white.opacity(hovering ? 0.1 : 0))
      .onContinuousHover { state in
        if case .active = state {
          hovering = true
        } else {
          hovering = false
        }
      }
  }
}

#Preview {
  ModelSelectionView()
}
