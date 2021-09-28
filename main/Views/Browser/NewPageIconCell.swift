//
//  NewPageIconCell.swift
//  main
//
//  Created by Ryu on 2021/05/23.
//

import Foundation
import UIKit

protocol NewPageIconCellDelegate : AnyObject {
    func removeCell(cell:NewPageIconCell)
}

class NewPageIconCell : UICollectionViewCell, Crop, FaviconOptimizer {
    
    weak var delegate:NewPageIconCellDelegate!
    var url = ""
    var icon = UIImageView()
    var removeIcon = UIButton()
    var stack = UIStackView().then {
        $0.alignment = .center
        $0.axis = .vertical
        $0.distribution = .equalSpacing
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    var title:String = ""
    var isEditingCell:Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func setIconAndUrl(url:String,title:String,size:Int,isEditing:Bool) {
        self.isEditingCell = isEditing
        let data = optimizeFaviconData(url: url)
        if !data.0 {
            FavIconFetcher.download(url:url) { result in
                if case let .success(image) = result {
                    DispatchQueue.main.async {
                        self.iconSet(image: image, url: url, size: size, title: title, crop: true)
                    }
                }
            }
        }else{
            self.iconSet(image: data.1!, url: url, size: size, title: title, crop: false)
        }
    }
    func urlToHostName(urlString:String) -> String {
        if let component: NSURLComponents = NSURLComponents(string: urlString) {
            return component.host ?? "about:blank"
        }else{
            return "about:blank"
        }
    }
    private func iconSet(image:UIImage,url:String,size:Int,title:String,crop:Bool) {
        self.title = title
        self.icon = crop ? UIImageView(image: cropThumbnailImage(image: image, w: size, h: size)).then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 5
        }:UIImageView(image: image).then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 7
            if image == UIImage(systemName: "plus") {
                $0.tintColor = .white
                $0.backgroundColor = .lightGray
                $0.layer.cornerRadius = 5
                $0.clipsToBounds = true
            }
        }
        if isEditingCell {
            self.removeIcon = UIButton().then {
                $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
                $0.addTarget(self, action: #selector(removeCell), for: .touchUpInside)
                $0.translatesAutoresizingMaskIntoConstraints = false
                $0.tintColor = .lightGray
            }
        }
        self.url = url
        self.setupIcon()
    }
    @objc func removeCell() {
        self.delegate.removeCell(cell: self)
    }
    private func setupIcon() {
        self.addSubview(stack)
        let titleLabel = UILabel().then {
            $0.text = title
            $0.textColor = .blackWhite
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textAlignment = .center
            $0.font = UIFont.systemFont(ofSize: 13)
        }
        stack.removeAllArrangedSubviews()
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        //print("stack111",stack.subviews)
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60),
            stack.topAnchor.constraint(equalTo: topAnchor,constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leftAnchor.constraint(equalTo: leftAnchor,constant: 6),
            stack.rightAnchor.constraint(equalTo: rightAnchor,constant:-6)
        ])
        if isEditingCell {
            self.addSubview(removeIcon)
            NSLayoutConstraint.activate([
                removeIcon.topAnchor.constraint(equalTo: self.topAnchor),
                removeIcon.rightAnchor.constraint(equalTo: self.rightAnchor)
            ])
        }
    }
}
protocol FaviconOptimizer {
    func urlToHostName(urlString:String) -> String
}
extension FaviconOptimizer {
    func optimizeFaviconData(url:String) -> (Bool,UIImage?) {
        let urls = ["https://www.google.co.jp","https://m.youtube.com","https://duckduckgo.com","https://mobile.twitter.com","https://www.amazon.co.jp","https://ja.m.wikipedia.org"]
        let imageArray:[String] = ["google.jpeg","youtube.png","duckduckgo.png","twitter.png","Amazon_icon.png","wiki.png"]
        var count = 0
        for u in urls {
            if urlToHostName(urlString: u) == urlToHostName(urlString: url){
                return (true,UIImage.convenienceInit(named: imageArray[count], size: CGSize(width: 60, height: 60)))
            }
            count+=1
        }
        return (false,nil)
    }
}
