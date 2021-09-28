//
//  AddViewController.swift
//  main
//
//  Created by Ryu on 2021/05/26.
//

import Foundation
import UIKit

protocol AddViewControllerDelegate : AnyObject {
    func reload()
}

class AddViewController : UIViewController {
    
    weak var delegate:AddViewControllerDelegate!
    var leftBarButton:UIBarButtonItem!
    var rightBarButton:UIBarButtonItem!
    var favoriteView:AddFavoriteWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        self.navigationItem.title = "Add Favorite"
        rightBarButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(tappedRightBarButton))
        leftBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(tappedLeftBarButton))
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.leftBarButtonItem = leftBarButton
        setupAddFavoriteView()
    }
    private func setupAddFavoriteView() {
        favoriteView = AddFavoriteWebView(frame: .zero)
        favoriteView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(favoriteView)
        NSLayoutConstraint.activate([
            favoriteView.topAnchor.constraint(equalTo: view.topAnchor,constant: 70),
            favoriteView.leftAnchor.constraint(equalTo: view.leftAnchor),
            favoriteView.rightAnchor.constraint(equalTo: view.rightAnchor),
            favoriteView.heightAnchor.constraint(equalToConstant: 75)
        ])
    }
    private func setupSaveCancelButton() {
        let cancelButton = UIButton().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setTitle("Cancel", for: .normal)
            $0.backgroundColor = UIColor(hex: "8CD790")
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 3
            $0.setTitleColor(.white, for: .normal)
        }
        let saveButton = UIButton().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.setTitle("Save", for: .normal)
            $0.backgroundColor = UIColor(hex: "8CD790")
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 3
            $0.setTitleColor(.white, for: .normal)
        }
        let HStack = UIStackView().then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .horizontal
            $0.distribution = .equalSpacing
            $0.alignment = .center
        }
        view.addSubview(HStack)
        HStack.addArrangedSubViews([cancelButton,saveButton])
    }
    @objc func tappedLeftBarButton() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func tappedRightBarButton() {
        if let saveURL = favoriteView.urlTextField.text,let saveTitle = favoriteView.titleTextField.text,saveURL != "",saveTitle != "" {
            var beforeURLs = UserDefaults.standard.array(forKey: "iconCell") as! [[String]]
            var beforeTitle = UserDefaults.standard.array(forKey: "titleCell") as! [[String]]
            beforeURLs[0].append(saveURL)
            beforeTitle[0].append(saveTitle)
            UserDefaults.standard.setValue(beforeURLs, forKey: "iconCell")
            UserDefaults.standard.setValue(beforeTitle, forKey: "titleCell")
            self.delegate.reload()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
