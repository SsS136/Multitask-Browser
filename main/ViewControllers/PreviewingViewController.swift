//
//  PreviewingViewController.swift
//  main
//
//  Created by Ryu on 2021/03/12.
//

import Foundation
import UIKit
import WebKit

class PreviewingViewController: UIViewController {
    var webViewPreviewActionItems: [UIPreviewActionItem] = []
    var linkURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Peek & Pop用のWKWebViewを表示
        if let url = self.linkURL {
            let web = WKWebView()
            web.frame = self.view.bounds
            self.view.addSubview(web)
            web.load(URLRequest(url: url))
        }
    }
}
