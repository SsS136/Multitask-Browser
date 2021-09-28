//
//  TabCollectionNavigationBar.swift
//  main
//
//  Created by Ryu on 2021/03/17.
//

import Foundation
import UIKit
protocol TabCollectionNavigationBarDelegate : AnyObject {
    func closeButtonTapped()
    func arrowButtonTapped()
}
protocol TabCollectionNavigationBarUIDelegate : AnyObject {
    func addButtonTapped()
    func onLongPress()
    func privateButtonTapped()
}
protocol TabCollectionNavigationBarData : AnyObject {
    func getData() -> displayMode
}
class TabCollectionNavigationBar : UIView, PrivateDataCore {
    let widthheightSize = 18
    weak var delegate:TabCollectionNavigationBarDelegate!
    weak var data:TabCollectionNavigationBarData!
    weak var uiDelegate:TabCollectionNavigationBarUIDelegate!
    var stack:UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    lazy var arrowButton:UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        button.tintColor = .text
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    lazy var privateButton:UIButton = {
        let button = UIButton()
        button.setTitle("Private", for: .normal)
        button.setTitleColor(.blackWhite, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.layer.cornerRadius = 2
        button.addTarget(self, action: #selector(privateButtonTapped), for: .touchUpInside)
        return button
    }()
    lazy var addButton:UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .text
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        button.addGestureRecognizer(recognizer)
        return button
    }()
    lazy var cancelButton:UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .text
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .background
        setupStack()
    }
    @objc func privateButtonTapped() {
        self.uiDelegate.privateButtonTapped()
        privateButton.backgroundColor = isPrivate ? .privateSelectedColor : .clear
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.data.getData() == .part ? arrowButton.setImage(UIImage(systemName: "arrow.left"), for: .normal) : arrowButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
    }
    func setupStack() {
        self.addSubview(stack)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 45).isActive = true
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8).isActive = true
        stack.addArrangedSubViews([arrowButton,privateButton,addButton,cancelButton])
        
        arrowButton.widthAnchor.constraint(equalToConstant: CGFloat(widthheightSize + 3)).isActive = true
        arrowButton.heightAnchor.constraint(equalToConstant: CGFloat(widthheightSize + 3)).isActive = true
        privateButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        privateButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        addButton.widthAnchor.constraint(equalToConstant: CGFloat(widthheightSize + 10)).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: CGFloat(widthheightSize + 10)).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: CGFloat(widthheightSize)).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: CGFloat(widthheightSize)).isActive = true
        
        arrowButton.addTarget(self, action: #selector(arrowButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func addButtonTapped() {
        self.uiDelegate.addButtonTapped()
    }
    @objc func cancelButtonTapped() {
        self.delegate.closeButtonTapped()
    }
    @objc func arrowButtonTapped() {
        self.delegate.arrowButtonTapped()
    }
    @objc func onLongPress() {
        self.uiDelegate.onLongPress()
    }
}
