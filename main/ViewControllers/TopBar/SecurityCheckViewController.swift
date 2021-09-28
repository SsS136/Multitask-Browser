//
//  SecurityCheckViewController.swift
//  practice
//
//  Created by Ryu on 2021/03/05.
//

import Foundation
import UIKit
protocol SecurityCheckViewControllerDelegate : AnyObject {
    func reloadWebView()
    func unableAdBlock()
}
class SecurityCheckViewController : UIViewController {
    weak var delegate:SecurityCheckViewControllerDelegate!
    var secView = SecurityCheckContentView()
    var count:Float = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        popoverPresentationController?.backgroundColor = .systemGray3
        view.backgroundColor = UIColor(hex: "010E32", alpha: 1.0)
//        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
        view.addSubview(secView)
        secView.delegate = self
        secView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        secView.topAnchor.constraint(equalTo: view.topAnchor, constant: 13).isActive = true
        secView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    }
//    @objc func timerUpdate() {
//        secView.swch.onTintColor = UIColor(hue: CGFloat(count), saturation: 0.5, brightness: 1.0, alpha: 1.0)
//        count+=0.001
//        if count == 1 {
//            count = 0
//        }
//    }
}
extension SecurityCheckViewController : SecurityCheckContentViewDelegate {
    func unableAdBlock() {
        self.delegate.unableAdBlock()
    }
    func reloadWebView() {
        self.delegate.reloadWebView()
    }
}
