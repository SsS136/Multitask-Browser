//
//  WebWindowNavigation.swift
//  main
//
//  Created by Ryu on 2021/05/30.
//

import Foundation
import UIKit

protocol WebWindowNavigationDelegate : AnyObject {
    func removeButtonTapped()
    func minimizeButtonTapped()
    func moveWebWindow(_ sender:UIPanGestureRecognizer)
    func plusIconTapped()
}

class WebWindowNavigation : UIView {
    
    weak var delegate:WebWindowNavigationDelegate!
    
    var stack = UIStackView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.distribution = .fillProportionally
        $0.alignment = .center
    }
    lazy var plusIcon = UIButton().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        $0.tintColor = .green
        $0.alpha = 0
        $0.addTarget(self, action: #selector(plusIconTapped), for: .touchUpInside)
    }
    override init(frame:CGRect) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .gray
        setupStack()
        setupSelfPanGesture()
    }
    @objc func plusIconTapped() {
        self.delegate.plusIconTapped()
    }
    func setupSelfPanGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(moveWebWindow(_ :)))
        self.addGestureRecognizer(gesture)
    }
    func setupStack() {
        self.addSubview(stack)
        let remove = UIButton().then {
            $0.setImage(UIImage(systemName: "xmark"), for: .normal)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.tintColor = .black
            $0.backgroundColor = UIColor(hex: "D3381C")
            $0.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        }
        let minus = UIButton().then {
            $0.setImage(UIImage(systemName: "minus"), for: .normal)
            $0.tintColor = .black
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = UIColor(hex: "F6ad49")
            $0.addTarget(self, action: #selector(minimizeButtonTapped), for: .touchUpInside)
        }

        stack.addArrangedSubViews([remove,minus])
        self.addSubview(plusIcon)
        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalToConstant: 70),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leftAnchor.constraint(equalTo: leftAnchor),
            remove.heightAnchor.constraint(equalToConstant: BrowserUX.webWindowNavigationHeight),
            minus.heightAnchor.constraint(equalToConstant: BrowserUX.webWindowNavigationHeight),
            plusIcon.topAnchor.constraint(equalTo: topAnchor,constant: -7),
            plusIcon.rightAnchor.constraint(equalTo: rightAnchor,constant: 7),

        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func removeButtonTapped() {
        self.delegate.removeButtonTapped()
    }
    @objc func minimizeButtonTapped() {
        self.delegate.minimizeButtonTapped()
    }
    @objc func moveWebWindow(_ sender:UIPanGestureRecognizer) {
        self.delegate.moveWebWindow(sender)
    }
}
