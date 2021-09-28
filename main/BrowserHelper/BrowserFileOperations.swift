//
//  BrowserFileOperations.swift
//  main
//
//  Created by Ryu on 2021/03/29.
//

import Foundation
import UIKit
import Tiercel

final class BrowserFileOperations {
    class func readFromFile(dir:String) -> String {
        guard let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return ""
        }
        let fileURL = dirURL.appendingPathComponent(dir)
        guard let fileContents = try? String(contentsOf: fileURL) else {
            return ""
        }
        return fileContents
    }
    class func writingToFile(text: String,dir:String) {
        guard let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let fileURL = dirURL.appendingPathComponent(dir)
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error: \(error)")
        }
    }
    class func getArrayFromJsonData(jsonData:Data) -> CellData? {
        do {
            let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments)
            return json as? CellData
        }catch{
            return nil
        }
    }
    class func readImage(dir:String) -> UIImage?  {
        let documentsURL:URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL:URL = documentsURL.appendingPathComponent(dir)
        return UIImage(contentsOfFile: fileURL.path)
    }
    class func returnDocumentsFullPath(name:String) -> URL {
        let documentsURL:URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL:URL = documentsURL.appendingPathComponent(name)
        return fileURL
    }
    class func getDictionaryFromJsonData(jsonData:Data,token:String) -> NSDictionary? {
        do {
            let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) // JSONの読み込み
            let tops = json as! NSArray
            for top in tops {
                let dic = top as! NSDictionary
                if dic["token"] as! String == token {
                    return dic
                }
            }
            return nil
        } catch {
            print("catch")
            return nil
        }
    }
    class func convertDictionaryToJson(dictionary:CellData) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let jsonStr = String(bytes: jsonData, encoding: .utf8)!
            return jsonStr
        } catch let error {
            print(error)
            return nil
        }
    }
    @discardableResult class func createDirToDocuments(_ dirname: String) -> Bool {
        let fileManager = FileManager.default
        let a = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).last?.appendingPathComponent(dirname, isDirectory: true)
        do {
            try fileManager.createDirectory(at: a!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        return true
    }
    class func randomString(length: Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
    class func saveImage(dir:String,name:String,data:Data) {
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/" + dir + "/" + name) {
            createDirToDocuments(dir)
        }
        try! data.write(to: (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).last?.appendingPathComponent(dir + "/" + name, isDirectory: true))!)
    }
    class func replaceData(dir:String,name:String,replaceData:Data) {
        let path = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask ).last?.appendingPathComponent(dir + "/" + name, isDirectory: true))
        do {
            try FileManager.default.removeItem(at: path!)
            saveImage(dir: dir, name: name, data: replaceData)
        }catch {
            print("""
                ***Browser replace Data Error***
                please look class replace Data method of BrowserFileOperations
                """)
        }
    }
    class func searchArray(fromToken:String,array:CellData) -> Int? {
        var count = 0
        for arr in array {
            let dic = arr as [String : Any]
            if dic["token"] as! String == fromToken {
                return count
            }
            count+=1
        }
        return nil
    }
    class func deleteData(dir:String,name:String) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent(dir + "/" + name, isDirectory: true)
        do {
            try FileManager.default.removeItem(at: path!)
        }catch{
            fatalError("removeError")
        }
    }
    @discardableResult class func deleteData(fullPath:URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: fullPath)
            return true
        }catch{
            return false
        }
    }
    class func getLastDirectoryName(url:String) -> String {
        let strings = url.components(separatedBy: "/")
        return strings.last!
    }
    class func rename(_ pathName: String, oldName: String, newName: String) -> Bool {
        let atPathName = "\(pathName)/\(oldName)"
        let toPathName = "\(pathName)/\(newName)"
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(atPath: atPathName, toPath: toPathName)
        } catch {
            return false
        }
        return true
    }
    @discardableResult class func remove(_ pathName: String) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: NSHomeDirectory() + "/Documents/" + pathName)
        } catch {
            return false
        }
        return true
    }
    @discardableResult class func removeDownloadItem(name:String) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: Cache.defaultDiskCachePathClosure("Downloads") + "/File/" + name)
        } catch {
            return false
        }
        return true
    }
    @discardableResult class func saveData(url:String,name:String) -> Bool {
        do {
            let data = try Data(contentsOf: URL(string: url)!)
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileName = name
            let path = documentDirectory?.appendingPathComponent(fileName)
            do{
                try data.write(to: path!, options: .atomic)
                return true
            }catch{
                return false
            }
        }catch{
           return false
        }
    }
    class func getDate(atPath:String) -> String {
        let manager = FileManager()
        let attributes = try! manager.attributesOfItem(atPath:atPath)
        let d = attributes[.modificationDate]! as! Date
        let a = d.description(with: Locale(identifier: Locale.current.identifier))
        return String(describing: a)
    }
    class func getDateFormatted(atPath:String) -> Date {
        let manager = FileManager()
        let attributes = try! manager.attributesOfItem(atPath:atPath)
        let d = attributes[.modificationDate]! as! Date
        return d
    }
    class func getFileSize(atPath:String) -> String {
        let manager = FileManager()
        let attributes = try! manager.attributesOfItem(atPath:atPath)
        let d = attributes[.size]!
        return String(describing: d)
    }
    class func getFileInfoListInDir(_ dirName: String) -> [String] {
        var files: [String] = []
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: dirName)
            return files
        } catch {
            return files
        }
    }
    class func getDownloadFileList() -> [String]? {
        var directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directory.appendPathComponent("Downloads/File")
        if let urlArray = try? FileManager.default.contentsOfDirectory(at: directory,includingPropertiesForKeys: [.contentModificationDateKey],options:.skipsHiddenFiles) {
            return urlArray.map {($0.lastPathComponent, (try? $0.resourceValues(forKeys:[.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)}.sorted(by: { $0.1 > $1.1 }).map { $0.0 }
        } else {
            return nil
        }
    }
}
