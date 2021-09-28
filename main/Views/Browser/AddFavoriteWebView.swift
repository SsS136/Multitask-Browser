//
//  AddFavoriteWebView.swift
//  main
//
//  Created by Ryu on 2021/05/29.
//
import Foundation
import UIKit
import Kanna

class AddFavoriteWebView : UIView {
    
    var VStack = UIStackView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.distribution = .equalCentering
        $0.alignment = .center
    }
    var HStack = UIStackView().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .horizontal
        $0.distribution = .equalCentering
        $0.alignment = .center
    }
    var iconImage = UIImageView(image: UIImage(named: "rocket.png")).then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    var urlTextField = UITextField().then {
        $0.placeholder = "Please enter the URL"
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 5
        $0.backgroundColor = .systemGray3
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    var titleTextField = UITextField().then {
        $0.placeholder = "Please enter the Title"
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 5
        $0.backgroundColor = .systemGray3
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    override init(frame:CGRect) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .background
        setupStack()
    }
    func setupStack() {
        self.addSubview(HStack)
        urlTextField.delegate = self
        urlTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        VStack.addArrangedSubViews([urlTextField,titleTextField])
        HStack.addArrangedSubViews([iconImage,VStack])
        NSLayoutConstraint.activate([
            HStack.topAnchor.constraint(equalTo: topAnchor),
            HStack.leftAnchor.constraint(equalTo: leftAnchor,constant: 20),
            HStack.rightAnchor.constraint(equalTo: rightAnchor,constant: -20),
            HStack.heightAnchor.constraint(equalTo:heightAnchor),
            VStack.heightAnchor.constraint(equalTo: HStack.heightAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 55),
            iconImage.heightAnchor.constraint(equalToConstant: 55),
            urlTextField.widthAnchor.constraint(equalTo:HStack.widthAnchor,multiplier: 0.7),
            titleTextField.widthAnchor.constraint(equalTo: HStack.widthAnchor,multiplier: 0.7),
            urlTextField.heightAnchor.constraint(equalToConstant: 30),
            titleTextField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension AddFavoriteWebView : UITextFieldDelegate {
    @objc func textFieldDidChange(_ sender:UITextField) {
        guard let text = sender.text else { return }
        FavIconFetcher.download(url: text) {(result) in
            if case let .success(image) = result {
                self.iconImage.setImage(newImage: image)
                var url = ""
                if text.hasPrefix("http") {
                    url = text
                }else{
                    if URLChecker(currentMode: .google).checkUrlOrNot(fieldText: text) {
                        url = "https://\(text)"
                    }
                }
                if let nonOptionalURL = URL(string: url),let doc = try? HTML(url: nonOptionalURL, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.titleTextField.text = doc.title == nil ? "" : doc.title
                    }
                }else{
                    DispatchQueue.main.async {
                        self.titleTextField.text = ""
                    }
                }
            }
        }
    }
}
class HStack : UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.axis = .horizontal
        self.distribution = .equalSpacing
        self.alignment = .center
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class VStack : UIStackView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.axis = .vertical
        self.distribution = .equalSpacing
        self.alignment = .center
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
