//
//  TabCollectionViewCell.swift
//  main
//
//  Created by Ryu on 2021/03/20.
//

import Foundation
import UIKit

protocol TabCollectionViewCellDelegate : AnyObject {
    func cancelButtonTapped(cell:TabCollectionViewCell)
}
class TabCollectionViewCell : UICollectionViewCell {
    
    fileprivate var iconView = UIImageView()
    fileprivate var snapView = UIImageView()
    var url = ""
    var token = ""
    weak var delegate:TabCollectionViewCellDelegate!
    let urlLabel = {() -> UILabel in
        let label = UILabel()
        label.textColor = .whiteBlack
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    lazy var cancelButton:UIButton = {
        let button = UIButton()
        button.setImage(UIImage.convenienceInit(named: "incorrect2", size: CGSize(width: 19, height: 19)), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    fileprivate lazy var baseView:UIView = {
        let base = UIView()
        base.backgroundColor = .blackWhite
        base.alpha = 0.7
        base.translatesAutoresizingMaskIntoConstraints = false
        return base
    }()
    fileprivate var stack:UIStackView = { () -> UIStackView in
        let s = UIStackView()
        s.alignment = .center
        s.axis = .horizontal
        s.distribution = .equalSpacing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    public func setIconAndSnapshot(favicon:UIImage,snapshot:UIImage,url:String,token:String) {
        iconView.setImage(newImage: favicon)
        snapView.setImage(newImage: snapshot)
        self.token = token
        iconView.translatesAutoresizingMaskIntoConstraints = false
        urlLabel.text = url
        setSnapshot()
        setNavigationbarBase()
    }
    override init(frame:CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        layer.cornerRadius = 7
    }
    private func setSnapshot() {
        snapView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(snapView)
        NSLayoutConstraint.activate([
            snapView.topAnchor.constraint(equalTo: self.topAnchor),
            snapView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            snapView.leftAnchor.constraint(equalTo: self.leftAnchor),
            snapView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    private func setNavigationbarBase() {
        addSubview(baseView)
        NSLayoutConstraint.activate([
            baseView.topAnchor.constraint(equalTo: self.topAnchor),
            baseView.leftAnchor.constraint(equalTo: self.leftAnchor),
            baseView.rightAnchor.constraint(equalTo: self.rightAnchor),
            baseView.heightAnchor.constraint(equalTo: self.heightAnchor,multiplier: 1/7)
        ])
        baseView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: baseView.topAnchor),
            stack.leftAnchor.constraint(equalTo: baseView.leftAnchor),
            stack.rightAnchor.constraint(equalTo: baseView.rightAnchor),
            stack.bottomAnchor.constraint(equalTo: baseView.bottomAnchor)
        ])
        
        stack.addArrangedSubViews([iconView,urlLabel,cancelButton])
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalTo: stack.heightAnchor, multiplier: 0.92),
            iconView.heightAnchor.constraint(equalTo: stack.heightAnchor, multiplier: 0.92)
        ])
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = iconView.bounds.width/2
        urlLabel.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.65).isActive = true
        urlLabel.heightAnchor.constraint(equalTo: stack.heightAnchor, multiplier: 0.7).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: stack.heightAnchor, multiplier: 0.92).isActive = true
        cancelButton.heightAnchor.constraint(equalTo: stack.heightAnchor, multiplier: 0.92).isActive = true
    }
    public func selected() {
        layer.borderColor = UIColor.collectionSelected.cgColor
        layer.borderWidth = 2.5
    }
    public func deselected() {
        layer.borderColor = UIColor.clear.cgColor
        layer.borderWidth = 0
    }
    @objc func cancelButtonTapped() {
        self.delegate.cancelButtonTapped(cell: self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        cancelButton.setImage(UIImage.convenienceInit(named: "incorrect2", size: CGSize(width: 19, height: 19)), for: .normal)
        //selected()
    }
}

extension UIImageView {
    public func setImage(newImage: UIImage) {
        DispatchQueue.main.async {
            self.image = newImage
            self.setNeedsLayout()
        }
    }
}
