//
//  TranslationView.swift
//  main
//
//  Created by Ryu on 2021/05/29.
//

import Foundation
import UIKit

protocol TranslationViewDelegate : AnyObject {
    func translateTapped()
}

class TranslationView : UIView {
    weak var delegate:TranslationViewDelegate!
    let availableLanguage = Locale.isoLanguageCodes
    let aboveHStack = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .equalCentering
        $0.alignment = .center
        $0.spacing = 22
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    let VStack = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fillProportionally
        $0.alignment = .center
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    private let pointSize = CGFloat(18)
    override init(frame:CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(hex: "34373A")
        self.clipsToBounds = true
        self.layer.cornerRadius = 7
        setupStackView()
    }
    func setupStackView() {
        let translateInto = UILabel().then {
            $0.text = "Do you want to translate this page?"
            $0.textColor = .white
            $0.textAlignment = .center
            $0.adjustsFontSizeToFitWidth = true
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        let translate = UIButton().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setTitle("Translate", for: .normal)
            $0.setTitleColor(UIColor(hex: "7DB5FD"), for: .normal)
            $0.addTarget(self, action: #selector(translateTapped), for: .touchUpInside)
        }
        self.addSubview(VStack)
        VStack.addArrangedSubViews([aboveHStack])
        aboveHStack.addArrangedSubViews([translateInto,translate])
        NSLayoutConstraint.activate([
            VStack.topAnchor.constraint(equalTo: topAnchor),
            VStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            VStack.leftAnchor.constraint(equalTo: leftAnchor),
            VStack.rightAnchor.constraint(equalTo: rightAnchor),
            aboveHStack.heightAnchor.constraint(equalTo: VStack.heightAnchor)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func translateTapped() {
        self.delegate.translateTapped()
    }
}
