//
//  BrowserTabBarCell.swift
//  main
//
//  Created by Ryu on 2021/04/19.
//

import Foundation
import UIKit
protocol BrowserTabBarCellDelegate : AnyObject {
    func didDeleteTab(cell:BrowserTabBarCell)
}
class BrowserTabBarCell : UICollectionViewCell {
    fileprivate var title:String = ""
    var token:String = ""
    weak var delegate:BrowserTabBarCellDelegate!
    static var bcColor = UIColor.background
    
    var titleLabel:UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .blackWhite
        label.textAlignment = .center
        return label
    }()
    private let stack:UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    lazy var cancelButton:UIButton = {
        let button = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 13)
        button.setImage(UIImage(systemName: "xmark",withConfiguration: configuration), for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .blackWhite
        return button
    }()
    override init(frame:CGRect) {
        super.init(frame: .zero)
        super.backgroundColor = Self.bcColor
        self.layer.borderWidth = 0.3
        self.layer.borderColor = UIColor.borderColor.cgColor
        setLayout()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.layer.borderColor = UIColor.borderColor.cgColor
    }
    public func setTitle(title:String,token:String) {
        titleLabel.text = title
        self.token = token
    }
    private func setLayout() {
        self.addSubview(stack)
        stack.addArrangedSubViews([titleLabel,cancelButton])
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stack.leftAnchor.constraint(equalTo: self.leftAnchor),
            stack.rightAnchor.constraint(equalTo: self.rightAnchor),
            titleLabel.heightAnchor.constraint(equalTo:stack.heightAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 20),
            cancelButton.heightAnchor.constraint(equalTo: stack.heightAnchor)
        ])
    }
    public func selected() {
        self.backgroundColor = .selected
    }
    public func deselected() {
        self.backgroundColor = .background
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc private func cancelButtonTapped() {
        self.delegate.didDeleteTab(cell: self)
    }
}
