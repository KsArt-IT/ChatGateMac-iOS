//
//  TabType.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import Foundation

enum TabType: String, CaseIterable {
    case chatGPT
    case youtube
    case translator
    
    var title: String {
        switch self {
        case .chatGPT: "ChatGPT"
        case .youtube: "YouTube"
        case .translator: "Переводчик"
        }
    }
    
    var icon: String {
        switch self {
        case .chatGPT: "message.fill"
        case .youtube: "play.rectangle.fill"
        case .translator: "character.bubble"
        }
    }
}
