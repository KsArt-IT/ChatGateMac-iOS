//
//  TranslatorView.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI

struct TranslatorView: View {
    @ObservedObject var webViewStore: WebViewStore
    
    var body: some View {
        WebView(webViewStore: webViewStore, url: URL(string: "https://translate.google.com")!)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
