//
//  SearchEngineCellView.swift
//  practice
//
//  Created by Ryu on 2021/03/04.
//

import Foundation
import UIKit

class SearchEngineCellView : UIView {
    var imageButton = UIButton()
    var searchEngineNameLabel = UIButton()
    
    init(image:UIImage?,title:String,tag:Int) {
        super.init(frame:.zero)
        
        self.backgroundColor = UIColor(hex: "010E32", alpha: 1.0)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 44).isActive = true
        self.widthAnchor.constraint(equalToConstant: 175).isActive = true
        
        let stack = UIStackView()
        self.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.90).isActive = true
        stack.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing

        imageButton.setImage(image, for: .normal)
        imageButton.tag = tag
        stack.addArrangedSubview(imageButton)
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        imageButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        imageButton.clipsToBounds = true
        imageButton.layer.cornerRadius = 15
        imageButton.addTarget(self, action: #selector(SearchEngineCellView.tapEngine(sender:)),
                                 for: .touchUpInside)
        
        searchEngineNameLabel.setTitle(title, for: .normal)
        searchEngineNameLabel.titleLabel?.adjustsFontSizeToFitWidth = true
        searchEngineNameLabel.tag = tag
        stack.addArrangedSubview(searchEngineNameLabel)
        searchEngineNameLabel.translatesAutoresizingMaskIntoConstraints = false
        searchEngineNameLabel.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.79).isActive = true
        searchEngineNameLabel.addTarget(self, action: #selector(SearchEngineCellView.tapEngine(sender:)),
                                 for: .touchUpInside)
    }
    init() {
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func tapEngine(sender: UIButton) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "dismiss.action")))
        NotificationCenter.default.post(name: Notification.Name(rawValue: "change.action"), object: nil, userInfo: ["tag": "\(sender.tag)"])
    }
}
