import UIKit

class SettingsViewController : UIViewController,UITableViewDelegate,UITableViewDataSource {
    var leftBarButton: UIBarButtonItem!
    var settingsTableView:UITableView!
    let navBar = UINavigationBar(frame: .zero)
    var sectionTitle = ["Appearance","Search","About app"]
    var cellTitles = [["Theme","Bottom Bar","Search Bar"],["Download","Block Unencrypted Webpages","Get Suggestion","URL Autocomplete","Mode"],["Developer","About Browser","Rate Browser","Version"]]
    var detailTexts = [["Space"],[UserDefaults.standard.string(forKey:"mode")],["0.0.1"]]
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.background
        self.navigationItem.title = "Settings"

        leftBarButton = UIBarButtonItem(title: "done", style: .plain, target: self, action: #selector(tappedLeftBarButton))
        self.navigationItem.leftBarButtonItem = leftBarButton
        setupTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(modeChange(notification:)), name: Notification.Name("mode.action"), object: nil)
    }
    @objc func tappedLeftBarButton() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func modeChange(notification:NSNotification?) {
        let d = notification?.userInfo!["mode"]
        guard let data = d else {
            print("empty data")
            return
        }
        let st = data as! String
        detailTexts[1].remove(at: 0)
        detailTexts[1].insert(st, at: 0)
        settingsTableView.reloadData()
    }
    func setupTableView() {
        settingsTableView = UITableView(frame: .zero, style: .grouped)
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.rowHeight = UITableView.automaticDimension
        settingsTableView.separatorStyle = .singleLine
        self.view.addSubview(settingsTableView)
        settingsTableView.translatesAutoresizingMaskIntoConstraints = false
        settingsTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        settingsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        settingsTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        settingsTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    @objc func buttonStateChanged(sender:UISwitch) {
        let forkeys = ["blockhttp","suggestion","auto"]
        UserDefaults.standard.set(sender.isOn,forKey: forkeys[sender.tag - 100])
        if sender.tag == 102 {
            let bool = sender.isOn ? "true" : "false"
            NotificationCenter.default.post(name: Notification.Name(rawValue: "auto.action"), object: nil, userInfo: ["auto": bool])
        }
    }
}

extension SettingsViewController {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitle.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTitles[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "Settings")
        let sw = { (Tag:Int,isOn:Bool) -> UISwitch in
            let button = UISwitch()
            button.tag = Tag
            button.isOn = isOn
            button.addTarget(self, action: #selector(self.buttonStateChanged(sender:)), for: .touchUpInside)
            return button
        }
        UserDefaults.standard.register(defaults: ["suggestion" : true,"auto" : true])

        switch indexPath.section {
            case 0:
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = cellTitles[0][indexPath.row]
                switch indexPath.row {
                    case 0:
                        cell.detailTextLabel?.text = detailTexts[0][0]
                    default:
                        break
                }
            case 1:
                switch indexPath.row {
                    case 1:
                        cell.accessoryType = .none
                        cell.accessoryView = sw(100,UserDefaults.standard.bool(forKey: "blockhttp"))
                    case 2:
                        cell.accessoryType = .none
                        cell.accessoryView = sw(101,UserDefaults.standard.bool(forKey: "suggestion"))
                    case 3:
                        cell.accessoryType = .none
                        cell.accessoryView = sw(102,UserDefaults.standard.bool(forKey: "auto"))
                    case 4:
                        cell.detailTextLabel?.text = detailTexts[1][0]
                        cell.accessoryType = .disclosureIndicator
                    default:
                        cell.accessoryType = .disclosureIndicator
                }
                cell.textLabel?.text = cellTitles[1][indexPath.row]
            case 2:
                switch indexPath.row {
                    case 3:
                        cell.detailTextLabel?.text = detailTexts[2][0]
                        cell.accessoryType = .none
                    default:
                        cell.accessoryType = .disclosureIndicator
                        break
                }
                cell.textLabel?.text = cellTitles[2][indexPath.row]
            default:
                break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(50)
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(50)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 4:
                let uv = ModeViewController()
                self.navigationController?.pushViewController(uv, animated: true)
                break
            default:
                break
            }
        default:
            break
        }
    }
}
