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
    
    private let stateManager = WebViewStateManager.shared
    
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
        guard !loadedTabs.contains(tab) else { return }
        
        loadedTabs.insert(tab)
        _ = getOrCreateStore(for: tab)
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
                loadTab(for: .chatGPT)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Загружаем вкладку при первом переключении
                loadTab(for: newValue)
            }
            
            // Панель переключения и управления внизу
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
            .frame(height: 30)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}

#Preview {
    ContentView()
}
