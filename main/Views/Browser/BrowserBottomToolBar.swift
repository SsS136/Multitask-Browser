//
//  BrowserBottomToolBar.swift
//  main
//
//  Created by Ryu on 2021/04/21.
//

import Foundation
import UIKit

protocol BrowserBottomToolBarDelegate : AnyObject {
    func backButtonTapped()
    func forwardButtonTapped()
    func addWebView()
    @discardableResult func addWebWindow() -> WebWindow
    func overviewButtonTapped()
    func shareButtonTapped()
    func onLongPress()
    func webWindowAllRemove()
}

class BrowserBottomToolBar : UIView {
    
    weak var delegate:BrowserBottomToolBarDelegate!
    
    var backButton = UIButton()
    var forwardButton = UIButton()
    var addWindowButton = UIButton()
    var addButton = UIButton()
    var overviewButton = UIButton()
    var shareButton = UIButton()
    
    let stack:UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    func setupButtons() {
        let button = { [unowned self] (name:String,selecter:Selector) -> UIButton in
            let b = UIButton()
            b.setImage(UIImage(systemName: name,withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)), for: .normal)
            b.tintColor = .blackWhite
            b.translatesAutoresizingMaskIntoConstraints = false
            b.addTarget(self, action:selecter , for: .touchUpInside)
            return b
        }
        let names:[String]
        if #available(iOS 14, *) {
            names = ["chevron.backward","chevron.forward","plus","macwindow.badge.plus","ellipsis","square.and.arrow.up"]
        }else{
            names = ["arrow.left","arrow.right","plus","plus.rectangle.on.rectangle","ellipsis","square.and.arrow.up"]
        }
        backButton = button(names[0],#selector(backButtonTapped))
        forwardButton = button(names[1],#selector(forwardButtonTapped))
        addButton = button(names[2],#selector(addButtonTapped))
        addWindowButton = button(names[3],#selector(addWindowButtonTapped))
        overviewButton = button(names[4],#selector(overviewButtonTapped))
        shareButton = button(names[5],#selector(shareButtonTapped))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addWebWindowLongPressed))
        addWindowButton.addGestureRecognizer(longPress)
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        addButton.addGestureRecognizer(recognizer)
    }
    override init(frame:CGRect) {
        super.init(frame:.zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .background
        self.addSubview(stack)
        setupButtons()
        stack.addArrangedSubViews([backButton,forwardButton,addButton,addWindowButton,overviewButton,shareButton])
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stack.leftAnchor.constraint(equalTo: self.leftAnchor),
            stack.rightAnchor.constraint(equalTo: self.rightAnchor),
            backButton.heightAnchor.constraint(equalTo: stack.heightAnchor),
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
            forwardButton.heightAnchor.constraint(equalTo: stack.heightAnchor),
            forwardButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
            addButton.heightAnchor.constraint(equalTo: stack.heightAnchor),
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
            addWindowButton.heightAnchor.constraint(equalTo: stack.heightAnchor),
            addWindowButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
            overviewButton.heightAnchor.constraint(equalTo: stack.heightAnchor),
            overviewButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 55),
            shareButton.heightAnchor.constraint(equalTo: stack.heightAnchor),
            shareButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 55)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func backButtonTapped() {
        self.delegate.backButtonTapped()
    }
    @objc func forwardButtonTapped() {
        self.delegate.forwardButtonTapped()
    }
    @objc func addButtonTapped() {
        self.delegate.addWebView()
    }
    @objc func addWindowButtonTapped() {
        self.delegate.addWebWindow()
    }
    @objc func overviewButtonTapped() {
        self.delegate.overviewButtonTapped()
    }
    @objc func shareButtonTapped() {
        self.delegate.shareButtonTapped()
    }
    @objc func onLongPress() {
        self.delegate.onLongPress()
    }
    @objc func addWebWindowLongPressed() {
        self.delegate.webWindowAllRemove()
    }
}
