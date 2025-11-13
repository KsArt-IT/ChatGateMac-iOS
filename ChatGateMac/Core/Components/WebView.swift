//
//  WebView.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI
import WebKit
import AppKit

struct WebView: NSViewRepresentable {
    @ObservedObject var webViewStore: WebViewStore
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        // Требуем действие пользователя для воспроизведения
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        
        let webView = FullScreenWKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsMagnification = true
        
        webViewStore.webView = webView
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Обновление не требуется
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(webViewStore: webViewStore)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let webViewStore: WebViewStore
        
        init(webViewStore: WebViewStore) {
            self.webViewStore = webViewStore
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webViewStore.canGoBack = webView.canGoBack
            webViewStore.canGoForward = webView.canGoForward
            
            // Сохраняем текущий URL
            if let url = webView.url?.absoluteString {
                webViewStore.updateURL(url)
            }
        }
        
        // Поддержка полноэкранного режима
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

// Кастомный WKWebView с поддержкой fullscreen
class FullScreenWKWebView: WKWebView {
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        // Удаляем ненужные пункты меню
        menu.items.removeAll { item in
            item.identifier?.rawValue.contains("WKMenuItemIdentifier") == true
        }
        super.willOpenMenu(menu, with: event)
    }
}
