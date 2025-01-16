//
//  PromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PromptView: View {

    @ObservedObject var prompt: Prompt
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
      }

      @ViewBuilder
      var content: some View {
          switch prompt.generationState {
          case .generating:
              PromptDivider()
              GeneratingView(prompt: prompt)
          case .generated:
              GeneratedView(prompt: prompt)
          case .error(let error):
              GeneratedErrorView(error: error)
          default:
              EmptyView()
          }
      }
  }

  #Preview {
      // TODO bring back the previews.. 
//      PromptView()
  }
