//
//  BingPictureManager.swift
//  BingPaper
//
//  Created by Peng Jingwen on 2015-07-12.
//  Copyright (c) 2015 Peng Jingwen. All rights reserved.
//

import Cocoa

class BingPictureManager {
    
    var pastWallpapersRange = 15
    var workDirectory = "\(NSHomeDirectory())/Pictures/BingPaper"
    
    let netRequest = NSMutableURLRequest()
    let fileManager = FileManager.default
    
    init() {
        self.netRequest.cachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
        self.netRequest.timeoutInterval = 15
        self.netRequest.httpMethod = "GET"
    }
    
    fileprivate func checkAndCreateWorkDirectory() {
        do {
            try self.fileManager.createDirectory(
                atPath: self.workDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch _ {}
    }
    
    fileprivate func obtainWallpaper(atIndex: Int, atRegion: String) {
        let baseURL = "http://www.bing.com/HpImageArchive.aspx"
        self.netRequest.url = URL(string: "\(baseURL)?format=js&n=1&idx=\(atIndex)&mkt=\(atRegion)")

        let reponseData = try? NSURLConnection.sendSynchronousRequest(
            self.netRequest as URLRequest,
            returning: nil
        )
        
        if let dataValue = reponseData {
            let data = try? JSONSerialization.jsonObject(with: dataValue, options: []) as AnyObject
            
            if let objects = data?.value(forKey: "images") as? [NSObject] {
                if let startDateString = objects[0].value(forKey: "startdate") as? String,
                    let urlString = objects[0].value(forKey: "url") as? String {
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd"
                    if let startDate = formatter.date(from: startDateString) {
                        formatter.dateFormat = "yyyy-MM-dd"
                        let dateString = formatter.string(from: startDate)
                        
                        let infoPath = "\(self.workDirectory)/\(dateString)_\(atRegion).json"
                        let imagePath = "\(self.workDirectory)/\(dateString)_\(atRegion).jpg"
                        
                        if !self.fileManager.fileExists(atPath: infoPath) {
                            try? dataValue.write(
                                to: URL(fileURLWithPath: infoPath), options: [.atomic]
                            )
                        }
                        
                        if !self.fileManager.fileExists(atPath: imagePath) {
                            self.checkAndCreateWorkDirectory()
                            
                            self.netRequest.url = URL.init(
                                string: "https://www.bing.com\(urlString)"
                            )
                            let imageResponData = try? NSURLConnection.sendSynchronousRequest(
                                self.netRequest as URLRequest, returning: nil
                            )
                            
                            try? imageResponData?.write(
                                to: URL(fileURLWithPath: imagePath), options: [.atomic]
                            )
                        }
                    }
                }
            }
        }
    }
    
    func fetchWallpapers(atRegin: String) {
        for index in -1...pastWallpapersRange {
            self.obtainWallpaper(atIndex: index, atRegion: atRegin)
        }
    }
    
    func fetchLastWallpaper(atRegin: String) {
        for index in -1...0 {
            self.obtainWallpaper(atIndex: index, atRegion: atRegin)
        }
    }
    
    func checkWallpaperExist(onDate: String, atRegion: String) -> Bool {
        let path = "\(self.workDirectory)/\(onDate)_\(atRegion).jpg"
        
        if self.fileManager.fileExists(atPath: path) {
            return true
        }
        
        return false
    }
    
    func getWallpaperInfo(onDate: String, atRegion: String) -> (copyright: String, copyrightLink: String) {
        let path = "\(self.workDirectory)/\(onDate)_\(atRegion).json"
        let jsonString = try? String.init(contentsOfFile: path)
        
        if let jsonData = jsonString?.data(using: String.Encoding.utf8) {
            let data = try? JSONSerialization.jsonObject(with: jsonData, options: []) as AnyObject
            
            if let objects = data?.value(forKey: "images") as? [NSObject] {
                if let copyrightString = objects[0].value(forKey: "copyright") as? String,
                    let copyrightLinkString = objects[0].value(forKey: "copyrightlink") as? String {
                    return (copyrightString, copyrightLinkString)
                }
            }
        }
        
        return ("", "")
    }
    
    func setWallpaper(onDate: String, atRegion: String) {
        let path = "\(self.workDirectory)/\(onDate)_\(atRegion).jpg"

        if self.checkWallpaperExist(onDate: onDate, atRegion: atRegion) {
            if let screens = NSScreen.screens() {
                for screen in screens {
                    do {
                        try NSWorkspace.shared().setDesktopImageURL(
                            URL(fileURLWithPath: path),
                            for: screen ,
                            options: [:])
                    } catch _ {
                    }
                }
            }
        }
        
    }
}
