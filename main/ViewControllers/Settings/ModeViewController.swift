//
//  ModeViewController.swift
//  main
//
//  Created by Ryu on 2021/03/12.
//

import Foundation
import UIKit

class ModeViewController : UIViewController, UITableViewDelegate,UITableViewDataSource {
    
    let array = ["Mobile","DeskTop"]
    var mobileCell = UITableViewCell()
    var deskCell = UITableViewCell()
    
    lazy var tableView = {() -> UITableView in
        let tv = UITableView(frame: .zero,style: .grouped)
        tv.separatorStyle = .singleLine
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.allowsMultipleSelection = false
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Mode"
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
}

extension ModeViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "mode"
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "Settings")
        switch indexPath.row {
            case 0:
                mobileCell = cell
            case 1:
                deskCell = cell
            default:
                break
        }
        let data = UserDefaults.standard.string(forKey:"mode")
        if data == "Mobile" && indexPath.row == 0 {
            cell.accessoryType = .checkmark
        }else if data == "DeskTop" && indexPath.row == 1 {
            cell.accessoryType = .checkmark
        }
        cell.selectionStyle = .none
        cell.textLabel?.text = array[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "mode.action"), object: nil, userInfo: ["mode": array[indexPath.row]])
        let cell = tableView.cellForRow(at:indexPath)
        cell?.accessoryType = .checkmark
        if indexPath.row == 0 {
            deskCell.accessoryType = .none
        }else{
            mobileCell.accessoryType = .none
        }
        UserDefaults.standard.set(array[indexPath.row], forKey:"mode")
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at:indexPath)
        cell?.accessoryType = .none
    }
}
