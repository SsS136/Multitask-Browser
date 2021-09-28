//
//  DownloadListViewController.swift
//  main
//
//  Created by Ryu on 2021/04/29.
//

import Foundation
import UIKit
import Tiercel
import QuickLook

protocol DownloadListViewControllerDelegate : AnyObject {
    func deleteAllDownloadItem()
    func deleteDownloadItem(url:String)
    func dismissAlertIndicator()
}

class DownloadListViewController : UIViewController, DateOptimizer {
    
    var leftBarButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem!
    var downloadsTableView:UITableView!
    weak var delegate:DownloadListViewControllerDelegate!
    private var selectedFileURL:URL!
    
    var filteredDate:[String] {
        get{
            let orderedSet: NSOrderedSet = NSOrderedSet(array: dates)
            let fix = orderedSet.array as! [String]
            return fix
        }
    }

    var fileNames = {() -> [String] in
        return BrowserFileOperations.getDownloadFileList() ?? []
    }
    var filePaths:[String] {
        get{
            return fileNames().map{Cache.defaultDiskCachePathClosure("Downloads") + "/File/" + $0}
        }
    }
    private var dates:[String] {
        get{
            return getDates(atPaths: filePaths)
        }
    }
    
    lazy var groupedFileName = {[weak self] () -> [[String]] in
        guard let self = self else { return [] }
        var grouped:[[String]] = []
        var arr:[String] = []
        self.filteredDate.forEach { date in
            self.downloads.forEach { (key,value) in
                if value == date {
                    arr.append(key)
                }
            }
            grouped.append(arr)
            arr = []
        }
        return grouped
    }
    
    private lazy var groupedFileConstant = groupedFileName()
    
    var downloads:[String:String] {
        get{
            var dic:[String:String] = [:]
            filePaths.enumerated().forEach {
                dic[$1] = dates[$0]
            }
            return dic
        }
    }
    
    private func showAlert() {
        let alert: UIAlertController = UIAlertController(title: "Note", message: "There is no download items.", preferredStyle:  UIAlertController.Style.alert)
        let confirm: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
 
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationItem()
        if filteredDate.count == 0 {
            showAlert()
        }
    }
    override func loadView() {
        super.loadView()

    }
    override func viewDidLayoutSubviews() {
        print("読み込み完了")
        //self.delegate.dismissAlertIndicator()
    }
    private func setupNavigationItem() {
        self.navigationItem.title = "Downloads"
        leftBarButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(tappedLeftBarButton))
        rightBarButton = UIBarButtonItem(title: "DeleteAll", style: .plain, target: self, action:#selector(tappedRightBarButton))
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    private func setupTableView() {
        downloadsTableView = UITableView(frame: .zero, style: .insetGrouped)
        downloadsTableView.delegate = self
        downloadsTableView.dataSource = self
        downloadsTableView.rowHeight = UITableView.automaticDimension
        downloadsTableView.separatorStyle = .singleLine
        downloadsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(downloadsTableView)
        NSLayoutConstraint.activate([
            downloadsTableView.topAnchor.constraint(equalTo:view.topAnchor),
            downloadsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            downloadsTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            downloadsTableView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    private func getSizeForByteFormat(indexPath:IndexPath) -> String {
        let name = BrowserFileOperations.getLastDirectoryName(url: groupedFileConstant[indexPath.section][indexPath.item])
        let size = BrowserFileOperations.getFileSize(name: name)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size) ?? 0)
    }
    
    func changeValue() {
        groupedFileConstant = groupedFileName()
        self.downloadsTableView.reloadData()
    }
    
    @objc func tappedLeftBarButton() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func tappedRightBarButton() {
        let alertController: UIAlertController = UIAlertController(title: "Note", message: "Are you sure you want to delete all the downloaded items??", preferredStyle:  UIAlertController.Style.alert)
        let confirm: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            self.removeAll()
            self.changeValue()
            self.showAlert()
        })
        let cancel: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive, handler:{
            (action: UIAlertAction!) -> Void in
        })
        alertController.addAction(confirm)
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func removeAll() {
        self.delegate.deleteAllDownloadItem()
        BrowserFileOperations.removeDownloadItems(names: self.fileNames())
    }
}

extension DownloadListViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedFileURL = URL(fileURLWithPath: groupedFileConstant[indexPath.section][indexPath.item])
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        self.navigationController?.pushViewController(previewController, animated: true)
        
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filteredDate[section]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredDate.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedFileConstant[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Downloads")
        let name = BrowserFileOperations.getLastDirectoryName(url: groupedFileConstant[indexPath.section][indexPath.item])
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = getSizeForByteFormat(indexPath: indexPath)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let name = BrowserFileOperations.getLastDirectoryName(url: groupedFileConstant[indexPath.section][indexPath.item])
            let  urls = BrowserFileOperations.readFromFile(dir: "task.txt").components(separatedBy: "\n")
            guard urls.count > 0 else { return }
            let filteredURLs = urls.filter{BrowserFileOperations.getLastDirectoryName(url: $0) != name}
            let url = urls.filter{BrowserFileOperations.getLastDirectoryName(url: $0) == name}.joined()
            BrowserFileOperations.writingToFile(text: filteredURLs.joined(separator: "\n"), dir: "task.txt")
            BrowserFileOperations.removeDownloadItem(name: name)
            self.delegate.deleteDownloadItem(url: url)
            changeValue()
            if filteredDate.count == 0 {
                showAlert()
            }
        }
    }
}

extension DownloadListViewController : QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return selectedFileURL as QLPreviewItem
    }
}

protocol DateOptimizer {}
extension DateOptimizer {
    func getDates(atPaths:[String]) -> [String] {
        let formatte = DateFormatter()
        formatte.dateFormat = DateFormatter.dateFormat(fromTemplate: "ydMMM", options: 0, locale: Locale(identifier: Locale.current.identifier))
        let d = atPaths.map { da -> String in
            let date = BrowserFileOperations.getDateFormatted(atPath: da)
            return formatte.string(from: date)
        }
        .sorted(by: {$0.compare($1) == .orderedAscending })
        return d
    }
}

fileprivate extension BrowserFileOperations {
    class func getFileSizes(atPaths:[String]) -> [String] {
        let size = atPaths.map{ Self.getFileSize(atPath: $0) }
        return size
    }
    class func getFileSize(name:String) -> String{
        let manager = FileManager()
        let attributes = try! manager.attributesOfItem(atPath:Cache.defaultDiskCachePathClosure("Downloads") + "/File/" + name)
        let d = attributes[.size]!
        return String(describing: d)
    }
    class func removeDownloadItems(names:[String]) {
        names.forEach{Self.removeDownloadItem(name: $0)}
    }
}
fileprivate extension Dictionary {
    init(keys: [Key], values: [Value]) {
        precondition(keys.count == values.count)
        self.init()
        keys.enumerated().forEach {
            self[$1] = values[$0]
        }
    }
}
