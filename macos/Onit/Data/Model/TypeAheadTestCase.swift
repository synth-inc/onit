//
//  TypeAheadCase.swift
//  Onit
//
//  Created by Kévin Naudin on 24/02/2025.
//

import SwiftData
import Foundation

@Model
final class TypeAheadTestCase {
    var applicationName: String
    var applicationTitle: String?
    var screenContent: String
    var currentText: String
    var precedingText: String
    var followingText: String
    
    var aiCompletion: String?
    var similarityScore: Double?
    
    var timestamp: Date
    
    init(
        applicationName: String,
        applicationTitle: String?,
        screenContent: String,
        currentText: String,
        precedingText: String,
        followingText: String
    ) {
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.screenContent = screenContent
        self.currentText = currentText
        self.precedingText = precedingText
        self.followingText = followingText
        self.timestamp = Date()
    }
} 
