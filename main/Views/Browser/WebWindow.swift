//
//  WebWindow.swift
//  main
//
//  Created by Ryu on 2021/05/30.
//

import Foundation
import UIKit
import WebKit

protocol WebWindowDelegate : AnyObject {
    func removeWindow(window:WebWindow)
    func minimizeWindow(window:WebWindow)
    func shrinkWebWindow(_ sender: UIPanGestureRecognizer,window:WebWindow)
    func moveWebWindow(_ sender: UIPanGestureRecognizer,window:WebWindow)
    func plusIconTapped()
}

class WebWindow : UIView, PrivateDataCore, WebRequirements {
    
    var delegate:WebWindowDelegate!
    var navigation = WebWindowNavigation(frame:.zero)
    var webView:BrowserWKWebView = BrowserWKWebView()
    var progressView:UIProgressView!
    var bottomToolBar:WebWindowBottomToolBar!
    var favicon = UIImage(named: "rocket.png")
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .lightGray
        setupNavigation()
        setupProgressView()
        setupBottomToolBar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.setupWebView()
            self.openUrl(urlString: "https://google.com")
            self.bottomToolBar.back.isEnabled = false
            self.bottomToolBar.forward.isEnabled = false
        }
    }
    deinit{
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "loading")
        webView.removeObserver(self, forKeyPath: "canGoBack")
        webView.removeObserver(self, forKeyPath: "canGoForward")
    }
    func setupConfiguration() -> WKWebViewConfiguration {
        var configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.preferences.javaScriptEnabled = true
        configuration = AdBlockHelper.startAdBlocking(configuration: configuration)
        UserDefaults.standard.register(defaults: ["cookies":[]])
        if isPrivate {
            configuration.websiteDataStore = .nonPersistent()
        }else{
            configuration.websiteDataStore = WKWebsiteDataStore.default()
            configuration.processPool = WKProcessPool.shared
        }
        return configuration
    }
    func setupWebView() {
        webView = BrowserWKWebView(frame: .zero, configuration: setupConfiguration())
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
        self.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: leftAnchor),
            webView.rightAnchor.constraint(equalTo: rightAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomToolBar.topAnchor)
        ])
    }
    func setupFetchedWebView(web:BrowserWKWebView) {
        web.navigationDelegate = self
        web.uiDelegate = self
        web.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        web.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        web.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        web.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
    }
    func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0
        progressView.tintColor = .red
        progressView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: navigation.bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            progressView.leftAnchor.constraint(equalTo: leftAnchor),
            progressView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
    func setupNavigation() {
        navigation.delegate = self
        self.addSubview(navigation)
        NSLayoutConstraint.activate([
            navigation.topAnchor.constraint(equalTo: topAnchor),
            navigation.leftAnchor.constraint(equalTo: leftAnchor),
            navigation.rightAnchor.constraint(equalTo: rightAnchor),
            navigation.heightAnchor.constraint(equalToConstant: BrowserUX.webWindowNavigationHeight)
        ])
    }
    func setupBottomToolBar() {
        bottomToolBar = WebWindowBottomToolBar(frame: .zero)
        bottomToolBar.delegate = self
        bottomToolBar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(bottomToolBar)
        NSLayoutConstraint.activate([
            bottomToolBar.leftAnchor.constraint(equalTo: leftAnchor),
            bottomToolBar.rightAnchor.constraint(equalTo: rightAnchor),
            bottomToolBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomToolBar.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {

            self.progressView.alpha = 1.0

            self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)

            if webView.estimatedProgress >= 1.0 {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0.0,
                    options: [.curveEaseOut],
                    animations: {
                        self.progressView.alpha = 0.0
                    },completion: {(finished : Bool) in
                        self.progressView.setProgress(0.0, animated: false)
                })
            }
        }
        else if keyPath == "canGoForward" {
            bottomToolBar.forward.isEnabled = webView.canGoForward
        }
        else if keyPath == "canGoBack" {
            bottomToolBar.back.isEnabled = webView.canGoBack
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension WebWindow : WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        FavIconFetcher.download(url: webView.url?.absoluteString ?? "https://google.com") { result in
            if case let .success(image) = result {
                DispatchQueue.main.async {
                    self.favicon = image
                }
            }
        }
    }
}
extension WebWindow : WebWindowBottomToolBarDelegate {
    func goBack() {
        webView.goBack()
    }
    
    func goForward() {
        webView.goForward()
    }
    
    func reload() {
        webView.reload()
    }
    func shrinkWebWindow(_ sender: UIPanGestureRecognizer) {
        self.delegate.shrinkWebWindow(sender,window: self)
    }
}
extension WebWindow : WebWindowNavigationDelegate {
    func plusIconTapped() {
        self.delegate.plusIconTapped()
    }
    
    func removeButtonTapped() {
        self.delegate.removeWindow(window: self)
    }
    
    func minimizeButtonTapped() {
        self.delegate.minimizeWindow(window: self)
    }
    
    func moveWebWindow(_ sender: UIPanGestureRecognizer) {
        self.delegate.moveWebWindow(sender,window: self)
    }
}

