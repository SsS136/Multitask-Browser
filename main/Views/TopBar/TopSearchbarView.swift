//
//  TopSearchbarView.swift
//  practice
//
//  Created by Ryu on 2021/03/03.
//

import Foundation
import UIKit
import SearchTextField

//delegate
protocol TopSearchbarViewDelegate : AnyObject {
    func loadWebView(textField:UITextField)//
    func reloadWebView()//
    func loadCancel()//
    func secureButtonTapped(sender: UIButton)//
    func changeView()//
    func editingChanged(sender:SearchTextField)//
    func cancelButtonTapped(host:Bool)//
    func settingsButtonTapped()//
    func rectangleButtonTapped()//
    func hideNewPage()//
    func cellTapped()
    func setupNewPageView()
}

class TopSearchbarView : UIView, UIPopoverPresentationControllerDelegate, UITextFieldDelegate, PrivateDataCore{
    
    var shieldButton = UIButton()
    var baseView = UIView()
    var stack = UIStackView()
    var textField = SearchTextField(frame: .zero)
    var googleButton = UIButton()
    var settingsgoogleButton = UIButton()
    var rectanglegoogleButton = UIButton()
    weak var delegate:TopSearchbarViewDelegate!
    var reloadButton = UIButton()
    var cancelButton = UIButton()
    var baseViewConstraint = NSLayoutConstraint()
    var baseViewConstraintLeft = NSLayoutConstraint()
    var cancelButtonConstraint = NSLayoutConstraint()
    var textFieldConstraint = NSLayoutConstraint()
    var googleButton2 = UIButton()
    var googleButtonConstraint = NSLayoutConstraint()
    
    override init(frame: CGRect) {
        print("start TopsearchbarViewInitialize")
        
        super.init(frame: .zero)
        //selfSetting
        self.backgroundColor = UIColor.background
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 44).isActive = true
        //baseViewSettings
        baseViewConstraint = baseView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        baseViewConstraintLeft = baseView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8)
        
        baseView.backgroundColor = .systemGray3
        self.addSubview(baseView)
        baseView.translatesAutoresizingMaskIntoConstraints = false
        baseViewConstraint.isActive = true
        baseViewConstraintLeft.isActive = true
        baseView.heightAnchor.constraint(equalTo: self.heightAnchor,multiplier: 0.88).isActive = true
        baseView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        baseView.layer.cornerRadius = 10
        
        //cancelButton settings
        cancelButtonConstraint = cancelButton.rightAnchor.constraint(equalTo:self.rightAnchor, constant: 120)
        
        self.addSubview(cancelButton)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.text, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(sender:)), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        cancelButtonConstraint.isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 12).isActive = true
        cancelButton.centerYAnchor.constraint(equalTo: baseView.centerYAnchor).isActive = true
    
        //UIStackViewSetting
        stack.backgroundColor = .clear
        baseView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.leftAnchor.constraint(equalTo: baseView.leftAnchor,constant: 6).isActive = true
        stack.rightAnchor.constraint(equalTo: baseView.rightAnchor,constant: -6).isActive = true
        stack.topAnchor.constraint(equalTo: baseView.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: baseView.bottomAnchor).isActive = true
        stack.centerXAnchor.constraint(equalTo: baseView.centerXAnchor).isActive = true
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        
        //circleSettings
        let c = UIImage(systemName: "lock.shield", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20))
        shieldButton = UIButton()
        shieldButton.setImage(c, for: .normal)
        shieldButton.imageView?.tintColor = .systemGray3
        shieldButton.addTarget(self, action: #selector(TopSearchbarView.circleTapped(sender:)), for: .touchUpInside)
        stack.addArrangedSubview(shieldButton)
        
        //textFieldSettings
        textField.backgroundColor = .systemGray3
        textField.filterStrings(AutoCompleteManager.currentList)
        textField.inlineMode = true
        textField.delegate = self
        textField.placeholder = "search or enter address"
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        stack.addArrangedSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textFieldConstraint = textField.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.5)
        textFieldConstraint.isActive = true
        
        let image = UIImage.convenienceInit(named: "refresh", size: CGSize(width: 16, height: 16))
        reloadButton.setImage(image, for: .normal)
        stack.addArrangedSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        reloadButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        reloadButton.clipsToBounds = true
        reloadButton.addTarget(self, action: #selector(TopSearchbarView.reloadPushed(sender:)),
                                 for: .touchUpInside)
        //imageSettings
        let googleImage = UIImage.convenienceInit(named: "google.png", size: CGSize(width: 30, height: 30))
        googleButton.setImage(googleImage, for: .normal)
        stack.addArrangedSubview(googleButton)
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        googleButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        googleButton.clipsToBounds = true
        googleButton.layer.cornerRadius = 15
        googleButton.addTarget(self, action: #selector(TopSearchbarView.chooseSearchEngine(sender:)),
                                 for: .touchUpInside)
        
        //googleButton2
        googleButton2.setImage(googleImage, for: .normal)
        googleButton2.addTarget(self, action: #selector(TopSearchbarView.chooseSearchEngine(sender:)),
                                for: .touchUpInside)
        googleButton2.clipsToBounds = true
        googleButton2.layer.cornerRadius = 15
        self.addSubview(googleButton2)
        googleButton2.translatesAutoresizingMaskIntoConstraints = false
        googleButton2.widthAnchor.constraint(equalToConstant: 30).isActive = true
        googleButton2.heightAnchor.constraint(equalToConstant: 30).isActive = true
        googleButtonConstraint = googleButton2.leftAnchor.constraint(equalTo: self.leftAnchor, constant: -76)
        googleButtonConstraint.isActive = true
        googleButton2.centerYAnchor.constraint(equalTo: baseView.centerYAnchor).isActive = true
        
        let pointImage = UIImage(named: "settings")
        let a = pointImage?.resize(targetSize: CGSize(width: 25, height: 25))
        let assetPoint = a?.imageAsset?.image(with: traitCollection)
        //let improvePoint = assetPoint?.convenienceInit(size: CGSize(width: 25, height: 25))
        settingsgoogleButton.setImage(assetPoint, for: .normal)
        settingsgoogleButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(settingsgoogleButton)
        settingsgoogleButton.translatesAutoresizingMaskIntoConstraints = false
        settingsgoogleButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        settingsgoogleButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        settingsgoogleButton.clipsToBounds = true
        
        let rectangleImage = UIImage(named:"rounded-rectangle")
        rectanglegoogleButton.setImage(rectangleImage, for: .normal)
        rectanglegoogleButton.addTarget(self, action: #selector(rectangleButtonTapped), for: .touchUpInside)
        stack.addArrangedSubview(rectanglegoogleButton)
        rectanglegoogleButton.translatesAutoresizingMaskIntoConstraints = false
        rectanglegoogleButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        rectanglegoogleButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        rectanglegoogleButton.clipsToBounds = true
        
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setImages(buttons: [settingsgoogleButton,reloadButton,rectanglegoogleButton],images: [UIImage(named: "settings")?.imageAsset?.image(with: traitCollection).resize(targetSize: CGSize(width: 25, height: 25)),UIImage(named: "refresh")?.imageAsset?.image(with: traitCollection).resize(targetSize: CGSize(width: 16, height: 16)),UIImage(named: "rounded-rectangle")?.imageAsset?.image(with: traitCollection).resize(targetSize: CGSize(width: 20, height: 20))])
    }
    func setImages(buttons:[UIButton],images:[UIImage?]) {
        var count = 0
        for button in buttons {
            button.setImage(images[count], for: .normal)
            count+=1
        }
    }
    @objc func rectangleButtonTapped() {
        self.delegate.rectangleButtonTapped()
    }
    @objc func settingsButtonTapped() {
        self.delegate.settingsButtonTapped()
    }
    @objc func chooseSearchEngine(sender:UIButton) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "tap.action")))
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
    }
    func textFieldShouldReturn(_ textField1: UITextField) -> Bool {
        textField.textFieldDidEndEditingOnExit()
        saveFrequentlySearchText(textField1)
        self.delegate.loadWebView(textField: textField1)
        return true
    }
    private func saveFrequentlySearchText(_ textField: UITextField) {
        guard let text = textField.text,text != "" else { return }
        guard !isPrivate else { return }
        var before = UserDefaults.standard.array(forKey: "tmpText") as! [String]
        before.append(text)
        print(before)
        UserDefaults.standard.setValue(before, forKey: "tmpText")
        let tmpCount = (UserDefaults.standard.array(forKey: "tmpText") as! [String])
            .filter {$0 == text}
            .count
        if tmpCount == 2 {
            var st = UserDefaults.standard.array(forKey: "Suggestion")
            st?.append(text)
            UserDefaults.standard.setValue(st, forKey: "Suggestion")
        }
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField == self.textField else {
            return
        }
        UserDefaults.standard.register(defaults: ["tmpText":[],"Suggestion":[]])
        self.delegate.changeView()
    }
    @objc func textFieldDidChange(_ sender: SearchTextField) {
        self.delegate.editingChanged(sender: sender)
    }
    @objc func reloadPushed(sender:UIButton) {
        self.delegate.reloadWebView()
    }
    @objc func cancelPushed(sender:UIButton) {
        self.delegate.loadCancel()
    }
    @objc func circleTapped(sender: UIButton) {
        self.delegate.secureButtonTapped(sender: sender)
    }
    @objc func cancelButtonTapped(sender:UIButton) {
        self.delegate.cancelButtonTapped(host: true)
    }
}
extension TopSearchbarView : AutoCompleteManagerDelegate {
    func fetchTopSearchbarViewDelegate() -> TopSearchbarView {
        return self
    }
}
