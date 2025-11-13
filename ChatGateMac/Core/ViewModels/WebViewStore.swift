//
//  WebViewStore.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import Foundation
import WebKit
import Combine

class WebViewStore: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var currentURL: String = ""
    
    weak var webView: WKWebView?
    var saveURLCallback: ((String) -> Void)?
    private var saveTimer: Timer?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func updateURL(_ url: String) {
        currentURL = url
        saveURLCallback?(url)
    }
    
    // Запуск периодического сохранения URL (для YouTube)
    func startPeriodicSaving() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let url = self.webView?.url?.absoluteString else { return }
            self.updateURL(url)
        }
    }
    
    func stopPeriodicSaving() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
    
    deinit {
        stopPeriodicSaving()
    }
}
