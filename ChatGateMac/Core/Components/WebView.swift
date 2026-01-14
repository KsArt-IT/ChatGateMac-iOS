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
        
        // Отключаем автозамену через JavaScript
        let disableAutocorrectScript = """
        (function() {
            function disableAutocorrect(element) {
                element.setAttribute('autocorrect', 'off');
                element.setAttribute('autocapitalize', 'off');
                element.setAttribute('spellcheck', 'false');
            }
            
            // Применяем к существующим элементам
            document.addEventListener('DOMContentLoaded', function() {
                document.querySelectorAll('input, textarea, [contenteditable]').forEach(disableAutocorrect);
            });
            
            // Наблюдаем за новыми элементами
            new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) {
                            if (node.matches && node.matches('input, textarea, [contenteditable]')) {
                                disableAutocorrect(node);
                            }
                            if (node.querySelectorAll) {
                                node.querySelectorAll('input, textarea, [contenteditable]').forEach(disableAutocorrect);
                            }
                        }
                    });
                });
            }).observe(document.documentElement, { childList: true, subtree: true });
        })();
        """
        
        // Полифилл для Fullscreen API (театральный режим для YouTube)
        let fullscreenPolyfill = """
        (function() {
            var isTheaterMode = false;
            
            // Функция для входа в театральный режим
            function enterTheaterMode() {
                if (isTheaterMode) return;
                isTheaterMode = true;
                
                // Создаем стили для театрального режима
                var style = document.createElement('style');
                style.id = 'yt-theater-mode-style';
                style.textContent = `
                    /* Скрываем все кроме плеера */
                    ytd-masthead,
                    #masthead-container,
                    ytd-watch-metadata,
                    #secondary,
                    #related,
                    ytd-comments,
                    #comments,
                    #below {
                        display: none !important;
                    }
                    
                    /* Растягиваем контейнер плеера */
                    ytd-watch-flexy {
                        min-height: 100vh !important;
                    }
                    
                    #primary-inner {
                        margin: 0 !important;
                        padding: 0 !important;
                    }
                    
                    #player-theater-container,
                    #player-container {
                        width: 100vw !important;
                        height: 100vh !important;
                        max-width: 100vw !important;
                        max-height: 100vh !important;
                        position: fixed !important;
                        top: 0 !important;
                        left: 0 !important;
                        z-index: 9999 !important;
                        background: black !important;
                    }
                    
                    #movie_player {
                        width: 100% !important;
                        height: 100% !important;
                    }
                    
                    body {
                        overflow: hidden !important;
                    }
                `;
                document.head.appendChild(style);
            }
            
            // Функция для выхода из театрального режима
            function exitTheaterMode() {
                if (!isTheaterMode) return;
                isTheaterMode = false;
                
                var style = document.getElementById('yt-theater-mode-style');
                if (style) {
                    style.remove();
                }
            }
            
            // Перехватываем requestFullscreen
            Element.prototype.requestFullscreen = function() {
                enterTheaterMode();
                return Promise.resolve();
            };
            
            Element.prototype.webkitRequestFullscreen = function() {
                enterTheaterMode();
                return Promise.resolve();
            };
            
            Element.prototype.webkitRequestFullScreen = function() {
                enterTheaterMode();
                return Promise.resolve();
            };
            
            // Перехватываем exitFullscreen
            document.exitFullscreen = function() {
                exitTheaterMode();
                return Promise.resolve();
            };
            
            document.webkitExitFullscreen = function() {
                exitTheaterMode();
                return Promise.resolve();
            };
            
            // Обработчик клавиши Escape
            document.addEventListener('keydown', function(e) {
                if ((e.key === 'Escape' || e.keyCode === 27) && isTheaterMode) {
                    exitTheaterMode();
                }
            }, true);
            
            // Эмулируем поддержку Fullscreen API
            Object.defineProperty(document, 'fullscreenEnabled', {
                get: function() { return true; }
            });
            
            Object.defineProperty(document, 'webkitFullscreenEnabled', {
                get: function() { return true; }
            });
        })();
        """
        
        let autocorrectUserScript = WKUserScript(source: disableAutocorrectScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        let fullscreenUserScript = WKUserScript(source: fullscreenPolyfill, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        configuration.userContentController.addUserScript(autocorrectUserScript)
        configuration.userContentController.addUserScript(fullscreenUserScript)
        
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
