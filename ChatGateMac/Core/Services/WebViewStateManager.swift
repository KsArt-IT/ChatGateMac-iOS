//
//  WebViewStateManager.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import Foundation

class WebViewStateManager {
    static let shared = WebViewStateManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let youtubeURL = "youtube_last_url"
        static let youtubeTimestamp = "youtube_last_timestamp"
        static let chatGPTURL = "chatgpt_last_url"
        static let translatorURL = "translator_last_url"
    }
    
    // Сохранение URL для YouTube с временной меткой
    func saveYouTubeURL(_ url: String) {
        defaults.set(url, forKey: Keys.youtubeURL)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.youtubeTimestamp)
        defaults.synchronize()
    }
    
    func saveChatGPTURL(_ url: String) {
        defaults.set(url, forKey: Keys.chatGPTURL)
    }
    
    func saveTranslatorURL(_ url: String) {
        defaults.set(url, forKey: Keys.translatorURL)
    }
    
    // Загрузка URL
    func loadYouTubeURL() -> String? {
        return defaults.string(forKey: Keys.youtubeURL)
    }
    
    func loadChatGPTURL() -> String? {
        return defaults.string(forKey: Keys.chatGPTURL)
    }
    
    func loadTranslatorURL() -> String? {
        return defaults.string(forKey: Keys.translatorURL)
    }
}
