//
//  WebView.swift
//  SuperLearn
//
//  Created by Thomas B on 5/15/25.
//


import SwiftUI
import WebKit

/// WebView包装器，用于在SwiftUI中展示网页内容
struct WebView: UIViewRepresentable {
    /// 网页地址
    let url: URL

    /// 创建并返回 WKWebView 实例
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // 载入网页请求
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    /// 当SwiftUI状态变化时更新 WKWebView（此处无需额外处理）
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

/// 使用 NavigationStack 展示 WebView 的界面
struct WebViewContainer: View {
    /// 要加载的网页地址字符串
    let urlString: String
    let title: String
    
    var body: some View {
        // 解包URL字符串，如果无效则展示空视图
        if let url = URL(string: urlString) {
            WebView(url: url)
                .navigationTitle("WebView")
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(.all)
                .onAppear {
                    HapticsManager.shared.playHapticFeedback()
                }
        } else {
            Text("无效的 URL")
                .onAppear {
                    HapticsManager.shared.playHapticFeedback()
                }
        }
    }
}

#Preview {
    WebViewContainer(urlString: "https://thomasb.top", title: "ThomasB")
}
