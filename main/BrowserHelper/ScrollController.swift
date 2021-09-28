//
//  ScrollController.swift
//  Browser
//
//  Created by Ryu on 2021/06/06.
//

import UIKit

class ScrollController : NSObject {
    
    enum ScrollState {
        case hide
        case hiding
        case exist
    }
    
    var webView:BrowserWKWebView? {
        return controller?.webView
    }
    var controller:BrowserViewController?
    
    fileprivate var scrollView:UIScrollView? {
        return webView?.scrollView
    }
    var scrollState:ScrollState = .exist {
        willSet{
            scrollView?.panGestureRecognizer.removeTarget(self, action: nil)
        }
        didSet{
            if scrollState == .hide {
                scrollView?.panGestureRecognizer.removeTarget(self, action: nil)
            }
            else if scrollState == .hiding {
                scrollView?.panGestureRecognizer.addTarget(self, action: #selector(panGesture(_:)))
                scrollView?.panGestureRecognizer.delegate = self
            }
        }
    }
    init(mainController:BrowserViewController) {
        super.init()
        self.controller = mainController
        scrollState = .hiding
        if let controller = controller {
            controller.refreshControll.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
            controller.refreshControll.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
            controller.webView.scrollView.refreshControl = controller.refreshControll
        }
    }
    @objc func panGesture(_ sender:UIPanGestureRecognizer) {
        print("ScrollState:",sender.location(in: webView))
    }
    @objc func refresh(sender: UIRefreshControl) {
        guard let url = controller?.webView.url else {
            return
        }
        controller?.webView.load(URLRequest(url: url))
    }
}
extension ScrollController : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("Gesture")
        return true
    }
}
extension ScrollController : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("Gesture")
    }
}
