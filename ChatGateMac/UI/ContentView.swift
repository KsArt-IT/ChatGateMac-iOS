//
//  ContentView.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabType = .chatGPT
    @State private var youtubeURL: String = ""
    @State private var loadedTabs: Set<TabType> = [] // Первая вкладка загружается сразу
    
    @State private var chatGPTStore: WebViewStore?
    @State private var youtubeStore: WebViewStore?
    @State private var translatorStore: WebViewStore?
    
    @State private var isFullscreen = false
    @State private var showMenuBar = true
    @State private var menuBarTimer: Timer?
    
    private let stateManager = WebViewStateManager.shared
    private let memoryManager = TabMemoryManager.shared
    
    private var currentStore: WebViewStore? {
        switch selectedTab {
        case .chatGPT: return chatGPTStore
        case .youtube: return youtubeStore
        case .translator: return translatorStore
        }
    }
    
    init() {
        // Настройка сохранения URL для каждого store
    }
    
    private func loadTab(for tab: TabType) {
        if loadedTabs.contains(tab) {
            // Обновляем время доступа для уже загруженной вкладки
            memoryManager.markTabAccessed(tab)
            return
        }
        
        loadedTabs.insert(tab)
        _ = getOrCreateStore(for: tab)
        memoryManager.markTabAccessed(tab)
    }
    
    private func unloadTab(_ tab: TabType) {
        // Не выгружаем активную вкладку
        guard tab != selectedTab else { return }
        
        print("🗑️ Выгружаем неактивную вкладку: \(tab.title)")
        
        // Очищаем ресурсы store перед удалением
        switch tab {
        case .chatGPT:
            chatGPTStore?.cleanup()
            chatGPTStore = nil
        case .youtube:
            youtubeStore?.cleanup()
            youtubeStore = nil
        case .translator:
            translatorStore?.cleanup()
            translatorStore = nil
        }
        
        loadedTabs.remove(tab)
        
        // Принудительная очистка памяти
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Даем время системе для освобождения ресурсов
        }
    }
    
    private func setupMemoryManager() {
        memoryManager.onTabShouldUnload = { tab in
            DispatchQueue.main.async {
                self.unloadTab(tab)
            }
        }
    }
    
    private func getOrCreateStore(for tab: TabType) -> WebViewStore {
        switch tab {
        case .chatGPT:
            if chatGPTStore == nil {
                chatGPTStore = WebViewStore()
            }
            return chatGPTStore!
        case .youtube:
            if youtubeStore == nil {
                youtubeStore = WebViewStore()
                youtubeStore?.saveURLCallback = { url in
                    stateManager.saveYouTubeURL(url)
                }
                youtubeStore?.startPeriodicSaving()
            }
            return youtubeStore!
        case .translator:
            if translatorStore == nil {
                translatorStore = WebViewStore()
            }
            return translatorStore!
        }
    }
    
    private func openYouTubeURL() {
        guard !youtubeURL.isEmpty else { return }
        
        var urlString = youtubeURL.trimmingCharacters(in: .whitespaces)
        
        // Если это ID видео, создаем полный URL
        if !urlString.contains("http") {
            urlString = "https://www.youtube.com/watch?v=\(urlString)"
        }
        
        if let url = URL(string: urlString) {
            youtubeStore?.webView?.load(URLRequest(url: url))
        }
    }
    
    private func toggleFullscreen() {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // Если активна вкладка YouTube, также переключаем театральный режим плеера
        if selectedTab == .youtube {
            toggleYouTubeTheaterMode()
        }
        
        window.toggleFullScreen(nil)
        // Состояние обновится автоматически через NotificationCenter
    }
    
    private func toggleYouTubeTheaterMode() {
        guard let webView = youtubeStore?.webView else { return }
        
        let script: String
        if isFullscreen {
            // Выходим из театрального режима
            script = """
            (function() {
                if (typeof document.exitFullscreen === 'function') {
                    document.exitFullscreen();
                }
            })();
            """
        } else {
            // Входим в театральный режим
            script = """
            (function() {
                var player = document.querySelector('#movie_player');
                if (player && typeof player.requestFullscreen === 'function') {
                    player.requestFullscreen();
                }
            })();
            """
        }
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("⚠️ YouTube theater mode error: \(error.localizedDescription)")
            } else {
                print("🎬 YouTube theater mode toggled")
            }
        }
    }
    
    private func hideMenuBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showMenuBar = false
        }
    }
    
    private func showMenuBarTemporarily() {
        // Отменяем предыдущий таймер
        menuBarTimer?.invalidate()
        
        // Показываем меню
        withAnimation(.easeInOut(duration: 0.3)) {
            showMenuBar = true
        }
        
        // Если в fullscreen режиме, скрываем через ... секунд
        if isFullscreen {
            menuBarTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                hideMenuBar()
            }
        }
    }
    
    private func setupMouseTracking() {
        // Отслеживание движения мыши
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { event in
            if self.isFullscreen && !self.showMenuBar {
                self.showMenuBarTemporarily()
            }
            return event
        }
    }
    
    private func setupFullscreenObserver() {
        // Отслеживаем вход в fullscreen
        NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isFullscreen = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.hideMenuBar()
            }
        }
        
        // Отслеживаем выход из fullscreen
        NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isFullscreen = false
            
            // Если активна вкладка YouTube, выходим из театрального режима
            if self.selectedTab == .youtube {
                self.exitYouTubeTheaterMode()
            }
            
            self.showMenuBarTemporarily()
            self.menuBarTimer?.invalidate()
            self.menuBarTimer = nil
        }
    }
    
    private func exitYouTubeTheaterMode() {
        guard let webView = youtubeStore?.webView else { return }
        
        let script = """
        (function() {
            if (typeof document.exitFullscreen === 'function') {
                document.exitFullscreen();
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("⚠️ YouTube theater mode exit error: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Основной контент - View создаются лениво при первом обращении
            ZStack {
                if loadedTabs.contains(.chatGPT), let store = chatGPTStore {
                    ChatGPTView(webViewStore: store)
                        .opacity(selectedTab == .chatGPT ? 1 : 0)
                        .zIndex(selectedTab == .chatGPT ? 1 : 0)
                }
                
                if loadedTabs.contains(.youtube), let store = youtubeStore {
                    YouTubeView(webViewStore: store)
                        .opacity(selectedTab == .youtube ? 1 : 0)
                        .zIndex(selectedTab == .youtube ? 1 : 0)
                }
                
                if loadedTabs.contains(.translator), let store = translatorStore {
                    TranslatorView(webViewStore: store)
                        .opacity(selectedTab == .translator ? 1 : 0)
                        .zIndex(selectedTab == .translator ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                setupMemoryManager()
                setupMouseTracking()
                setupFullscreenObserver()
                loadTab(for: .chatGPT)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Загружаем вкладку при первом переключении
                loadTab(for: newValue)
            }
            
            // Панель переключения и управления внизу
            if showMenuBar {
                menuBarView
            }
        }
    }
    
    private var menuBarView: some View {
        HStack(spacing: 0) {
                // Отступ слева для центрирования кнопок вкладок
                if selectedTab == .youtube {
                    Spacer()
                        .frame(width: 312) // Ширина строки ввода + кнопка play
                }
                
                // Кнопки переключения вкладок
                ForEach(TabType.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        icon: tab.icon,
                        iconTime: loadedTabs.contains(tab) ? "timer" : "minus",
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 8)
                
                // Кнопки управления WebView
                Button(action: { currentStore?.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                }
                .disabled(currentStore?.canGoBack != true)
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                Button(action: { currentStore?.goForward() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                }
                .disabled(currentStore?.canGoForward != true)
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                Button(action: { currentStore?.reload() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                // Кнопка fullscreen для окна
                Button(action: toggleFullscreen) {
                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                
                // Строка ввода для ютуб плеера
                if selectedTab == .youtube {
                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                    
                    TextField("URL или ID видео", text: $youtubeURL)
                        .textFieldStyle(.plain)
                        .frame(width: 250)
                        .padding(.horizontal, 8)
                        .onSubmit {
                            openYouTubeURL()
                        }
                    
                    Button(action: openYouTubeURL) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
            }
            .frame(height: 32)
            .background(Color(nsColor: .controlBackgroundColor))
            .transition(.move(edge: .bottom))
    }
}

#Preview {
    ContentView()
}
