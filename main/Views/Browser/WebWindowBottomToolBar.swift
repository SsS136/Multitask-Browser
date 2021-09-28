//
//  WebWindowBottomToolBar.swift
//  main
//
//  Created by Ryu on 2021/05/31.
//

import Foundation
import UIKit

protocol WebWindowBottomToolBarDelegate : AnyObject {
    func goBack()
    func goForward()
    func reload()
    func shrinkWebWindow(_ sender:UIPanGestureRecognizer)
}

class WebWindowBottomToolBar : UIView {
    
    weak var delegate:WebWindowBottomToolBarDelegate!
    
    @objc let back = UIButton().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 14, *) {
            $0.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        }else{
            $0.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        }
        $0.tintColor = .white
    }
    let forward = UIButton().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 14, *) {
            $0.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        }else{
            $0.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        }
        $0.tintColor = .white
    }
    let reloadButton = UIButton().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(UIImage(systemName: "gobackward"), for: .normal)
        $0.tintColor = .white
    }
    private lazy var movePan = UIImageView(image: UIImage(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")).then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = true
    }
    var stack = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.alignment = .center
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override init(frame:CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .lightGray
        setupStack()
    }
    private func setupStack() {
        self.addSubview(stack)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.shrinkWebWindow(_:)))
        movePan.addGestureRecognizer(panGesture)
        back.addTarget(self, action: #selector(self.goBack), for: .touchUpInside)
        forward.addTarget(self, action: #selector(self.goForward), for: .touchUpInside)
        reloadButton.addTarget(self, action: #selector(self.reload), for: .touchUpInside)
        stack.addArrangedSubViews([back,forward,reloadButton,movePan])
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leftAnchor.constraint(equalTo: leftAnchor),
            stack.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
    @objc private func goBack() {
        self.delegate.goBack()
    }
    @objc private func goForward() {
        self.delegate.goForward()
    }
    @objc private func reload() {
        self.delegate.reload()
    }
    @objc private func shrinkWebWindow(_ sender:UIPanGestureRecognizer) {
        self.delegate.shrinkWebWindow(sender)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
