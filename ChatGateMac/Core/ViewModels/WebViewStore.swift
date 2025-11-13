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
        stopPeriodicSaving() // Останавливаем предыдущий таймер
        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveYouTubePosition()
        }
    }
    
    // Сохранение позиции YouTube видео
    private func saveYouTubePosition() {
        guard let webView = webView,
              let urlString = webView.url?.absoluteString,
              urlString.contains("youtube.com/watch") else { return }
        
        // JavaScript для получения текущей позиции видео
        let script = """
        (function() {
            var video = document.querySelector('video');
            if (video && !video.paused && video.currentTime > 0) {
                return Math.floor(video.currentTime);
            }
            return null;
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            guard let self = self,
                  let currentTime = result as? Int,
                  currentTime > 0 else {
                // Если не удалось получить позицию, сохраняем просто URL
                self?.updateURL(urlString)
                return
            }
            
            // Добавляем временную метку в URL
            var components = URLComponents(string: urlString)
            var queryItems = components?.queryItems ?? []
            
            // Удаляем старую временную метку если есть
            queryItems.removeAll { $0.name == "t" }
            
            // Добавляем новую временную метку
            queryItems.append(URLQueryItem(name: "t", value: "\(currentTime)s"))
            components?.queryItems = queryItems
            
            if let urlWithTime = components?.url?.absoluteString {
                self.updateURL(urlWithTime)
            }
        }
    }
    
    func stopPeriodicSaving() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
    
    // Очистка ресурсов
    func cleanup() {
        stopPeriodicSaving()
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
        saveURLCallback = nil
    }
    
    deinit {
        cleanup()
        print("🗑️ WebViewStore деинициализирован")
    }
}
