//
//  SearchViewCell.swift
//  main
//
//  Created by Ryu on 2021/03/08.
//

import Foundation
import UIKit

enum SearchType : Int {
    case history = 1
    case suggest = 2
}
protocol SearchViewCellDelgate : AnyObject {
    func linkLoad(url:String)
}
class SearchViewCell : UIView {
    var stack = UIStackView()
    var imageButton = UIButton()
    var button = UIButton()
    var leftUp = UIButton()
    var URL:String = ""
    weak var delegate:SearchViewCellDelgate!
    
    init(type:SearchType,text:String,url:String) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 45).isActive = true
        self.addSubview(stack)
        
        URL = url
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 15).isActive = true
        stack.rightAnchor.constraint(equalTo: self.rightAnchor,constant: -15).isActive = true
        stack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stack.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing

        switch type {
            case .history:
                let image = UIImage(named: "history.png")
                let improve = image?.resize(targetSize: CGSize(width: 15, height: 15))
                imageButton.setImage(improve, for: .normal)

            case .suggest:
                let image = UIImage(named: "loupe.png")
                let improve = image?.resize(targetSize: CGSize(width: 15, height: 15))
                imageButton.setImage(improve ,for: .normal)
        }
        stack.addArrangedSubview(imageButton)
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        imageButton.heightAnchor.constraint(equalToConstant: 15).isActive = true
        imageButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
        imageButton.addTarget(self, action: #selector(linkLoad(sender:)), for: .touchUpInside)

        button.setTitle(text, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.textColor = .systemGray6
        button.addTarget(self, action: #selector(linkLoad(sender:)), for: .touchUpInside)
        stack.addArrangedSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.8).isActive = true
        
        let arrow = UIImage.convenienceInit(named: "left-up.png", size: CGSize(width: 15, height: 15))
        leftUp.setImage(arrow, for: .normal)
        leftUp.addTarget(self, action:#selector(linkLoad(sender:)), for: .touchUpInside)
        stack.addArrangedSubview(leftUp)
        leftUp.translatesAutoresizingMaskIntoConstraints = false
        leftUp.heightAnchor.constraint(equalToConstant: 15).isActive = true
        leftUp.widthAnchor.constraint(equalToConstant: 15).isActive = true
        
    }
    @objc func linkLoad(sender:UIButton) {
        self.delegate.linkLoad(url: URL)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
