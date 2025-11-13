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
        
        // Используем default store для сохранения cookies и сессий
        configuration.websiteDataStore = .default()
        
        // Общий process pool для всех WebView (экономия памяти)
        configuration.processPool = WKProcessPool.shared
        
        let webView = FullScreenWKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsMagnification = true
        
        // Оптимизация рендеринга
        webView.configuration.preferences.minimumFontSize = 0
        
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
    
    // Очистка при удалении
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.stopLoading()
        nsView.navigationDelegate = nil
        nsView.uiDelegate = nil
        coordinator.cleanup()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        weak var webViewStore: WebViewStore? // Используем weak для избежания retain cycle
        
        init(webViewStore: WebViewStore) {
            self.webViewStore = webViewStore
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webViewStore?.canGoBack = webView.canGoBack
            webViewStore?.canGoForward = webView.canGoForward
            
            // Сохраняем текущий URL
            if let url = webView.url?.absoluteString {
                webViewStore?.updateURL(url)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Обработка ошибок для предотвращения утечек
            print("⚠️ WebView navigation failed: \(error.localizedDescription)")
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
        
        func cleanup() {
            webViewStore = nil
        }
    }
}

// Shared process pool для экономии памяти
extension WKProcessPool {
    static let shared = WKProcessPool()
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
