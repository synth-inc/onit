//
//  StopMode.swift
//  Onit
//
//  Created by OpenAI on 2023-11-20.
//

import Defaults

enum StopMode: String, CaseIterable, Codable, Defaults.Serializable {
    case removePartial
    case leavePartial
}
