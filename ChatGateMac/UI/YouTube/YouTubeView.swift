//
//  YouTubeView.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI

struct YouTubeView: View {
    @ObservedObject var webViewStore: WebViewStore
    
    private var initialURL: URL {
        if let savedURL = WebViewStateManager.shared.loadYouTubeURL(),
           let url = URL(string: savedURL) {
            return url
        }
        return URL(string: "https://www.youtube.com")!
    }
    
    var body: some View {
        WebView(webViewStore: webViewStore, url: initialURL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
