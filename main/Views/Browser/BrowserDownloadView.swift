//
//  BrowserDownloadView.swift
//  main
//
//  Created by Ryu on 2021/04/17.
//

import Foundation
import UIKit
protocol BrowserDownloadViewDelegate : AnyObject {
    func deleteDownloadView()
}
class BrowserDownloadView : UIView {
    weak var delegate:BrowserDownloadViewDelegate!
    var progressView = UIProgressView(progressViewStyle: .bar)
    var downloadTitleLabel:UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    lazy var cancelLabel:UIButton = {
        let button = UIButton()
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    var progressByte:UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: 11)
        return label
    }()
    var vstack:UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .center
        s.distribution = .equalSpacing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    var hstack:UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    init(title:String) {
        super.init(frame: .zero)
        self.backgroundColor = .background
        self.translatesAutoresizingMaskIntoConstraints = false
        downloadTitleLabel.text = title
        setupProgressView()
    }
    func setupProgressView() {
        progressView.frame = .zero
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = .text
        self.addSubview(progressView)
        progressView.addSubview(hstack)
        
        hstack.addArrangedSubViews([vstack,cancelLabel])
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: self.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            progressView.leftAnchor.constraint(equalTo: self.leftAnchor),
            progressView.rightAnchor.constraint(equalTo: self.rightAnchor),
            hstack.topAnchor.constraint(equalTo: self.topAnchor),
            hstack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            hstack.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 10),
            hstack.rightAnchor.constraint(equalTo: self.rightAnchor,constant: -10),
            cancelLabel.widthAnchor.constraint(equalToConstant: 60),
            cancelLabel.heightAnchor.constraint(equalToConstant: 19)
        ])
        vstack.addArrangedSubViews([downloadTitleLabel,progressByte])
        NSLayoutConstraint.activate([
            vstack.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.65),
            vstack.widthAnchor.constraint(lessThanOrEqualTo: hstack.widthAnchor,multiplier: 0.8),
            downloadTitleLabel.widthAnchor.constraint(lessThanOrEqualTo: hstack.widthAnchor, multiplier: 0.8),
            downloadTitleLabel.heightAnchor.constraint(equalToConstant: 18),
            progressByte.widthAnchor.constraint(lessThanOrEqualTo: hstack.widthAnchor, multiplier: 0.8),
            progressByte.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
    @objc func cancelButtonTapped() {
        self.delegate.deleteDownloadView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
