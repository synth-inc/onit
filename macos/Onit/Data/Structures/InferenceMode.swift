//
//  InferenceMode.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Defaults

enum InferenceMode: String, CaseIterable, Codable, Defaults.Serializable {
  case local = "local"
  case remote = "remote"
}
