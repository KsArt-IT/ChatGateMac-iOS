//
//  ChatGPTView.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI

struct ChatGPTView: View {
    @ObservedObject var webViewStore: WebViewStore
    
    var body: some View {
        WebView(webViewStore: webViewStore, url: URL(string: "https://chat.openai.com")!)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
