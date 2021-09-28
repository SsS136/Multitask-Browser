//
//  BrowserDataReloader.swift
//  main
//
//  Created by Ryu on 2021/05/06.
//

import Foundation
import UIKit

protocol DataReloaderDataSource : AnyObject {
    func getRequiredInstance() -> (BrowserTabBarController,TabCollectionViewController)
}

struct DataReloader : PrivateDataCore {
    
    weak var data:DataReloaderDataSource!
    private weak var tabBar:BrowserTabBarController!
    private weak var tabCollection:TabCollectionViewController!
    
    private var isUsingDelegate:Bool
    
    static var isPrivate:Bool = false
    
    init(tab:BrowserTabBarController,collection:TabCollectionViewController) {
        self.isUsingDelegate = false
        self.tabBar = tab
        self.tabCollection = collection
    }
    init() {
        self.isUsingDelegate = true
        self.tabBar = nil
        self.tabCollection = nil
    }
    mutating func reloadAll() {
        setInstancesBasedOnDelegate()
        tabBar.reloadArray()
        tabCollection.reloadArray()
    }
    mutating func insert(at:[IndexPath],completionHandler: ((Bool) -> Void)?) {
        setInstancesBasedOnDelegate()
        let collections = [tabBar.collectionView,tabCollection.collectionView]
        collections.forEach { collection in
            collection.performBatchUpdates({
                DispatchQueue.main.async {
                    collection.insertItems(at: at)
                }
            }, completion: completionHandler)
        }
    }
    mutating func delete(at:[IndexPath],completionHandler: ((Bool) -> Void)?) {
        setInstancesBasedOnDelegate()
        let collections = [tabBar.collectionView,tabCollection.collectionView]
        collections.forEach { collection in
            collection.performBatchUpdates({
                DispatchQueue.main.async {
                    collection.deleteItems(at: at)
                }
            }, completion: completionHandler)
        }
    }
    mutating func update(at:[IndexPath],completionHandler: ((Bool) -> Void)?) {
        setInstancesBasedOnDelegate()
        let collections = [tabBar.collectionView,tabCollection.collectionView]
        collections.forEach { collection in
            collection.performBatchUpdates({
                DispatchQueue.main.async {
                    collection.reloadItems(at: at)
                }
            }, completion: completionHandler)
        }
    }
    mutating private func setInstancesBasedOnDelegate() {
        if isUsingDelegate {
            let data = self.data.getRequiredInstance()
            self.tabBar = data.0
            self.tabCollection = data.1
        }
    }
}
