//
//  MenuPopupController.swift
//  main
//
//  Created by Ryu on 2021/04/28.
//

import Foundation
import UIKit
protocol MenuPopupControllerDelegate : AnyObject {
    func settingsButtonTapped()
    func downloadsButtonTapped()
    func historyButtonTapped()
    func bookmarkButtonTapped()
}
class MenuPopupController : UITableViewController {
    
    let menu = ["Downloads","History","Bookmark","Settings","DeskTop"]
    var imageName:[String] = {
        if #available(iOS 14, *) {
            return ["arrow.down.to.line.alt","clock","book","gear","display"]
        }else{
            return ["arrow.down.to.line.alt","clock","book","gear","desktopcomputer"]
        }
    }()
    
    let mode = ["Mobile","DeskTop"]
    weak var delegate:MenuPopupControllerDelegate!
    static var cellColor = UIColor.background
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.cellColor
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "menu")
        self.tableView.isScrollEnabled = false
        self.tableView.separatorColor = Self.cellColor
        self.tableView.separatorInset = .zero
    }
    @objc func buttonStateChanged(sender:UISwitch) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "mode.action"), object: nil, userInfo: ["mode": sender.isOn ? mode[1] : mode[0]])
        UserDefaults.standard.set(sender.isOn ? mode[1] : mode[0], forKey:"mode")
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.tableView.reloadData()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sw = { (Tag:Int,isOn:String) -> UISwitch in
            let button = UISwitch()
            button.tag = Tag
            button.isOn = isOn == "DeskTop" ? true : false
            button.addTarget(self, action: #selector(self.buttonStateChanged(sender:)), for: .touchUpInside)
            button.backgroundColor = UIColor(hex: "D7D7FF")
            button.layer.cornerRadius = button.frame.height/2
            return button
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "menu", for: indexPath)
        cell.textLabel?.text = menu[indexPath.item]
        cell.textLabel?.textColor = .blackWhite
        cell.backgroundColor = Self.cellColor
        cell.imageView?.image = UIImage(systemName: imageName[indexPath.item],withConfiguration: UIImage.SymbolConfiguration(pointSize: 16))
        cell.tintColor = .blackWhite
        if menu[indexPath.item] == "DeskTop" {
            cell.accessoryView = sw(500,UserDefaults.standard.string(forKey: "mode") ?? "Mobile")
            cell.selectionStyle = .none
            //cell.separatorInset = .
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.item {
        case 0:
            self.delegate.downloadsButtonTapped()
        case 1:
            self.delegate.historyButtonTapped()
        case 2:
            self.delegate.bookmarkButtonTapped()
        case 3:
            self.delegate.settingsButtonTapped()
        default:
            break
        }
    }
}
