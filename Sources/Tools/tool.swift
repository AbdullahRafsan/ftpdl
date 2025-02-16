import Foundation
import SwiftSoup


let TIMEPASSBD_URL = "http://ftp.timepassbd.live"

func list(_ baseURL: String, _ path: String) {
    let fm = FileManager.default
    let cwd = FileManager.default.currentDirectoryPath
    let dirName = getName(path.decodeUrl())
    let relativePath = "\(cwd)/\(getName(path))"
    let finalURL = "\(baseURL)\(path)"
    do {
        if !fm.fileExists(atPath: relativePath) {
            print("Creating \(dirName)")
            try fm.createDirectory(atPath: relativePath, withIntermediateDirectories: false)
        }
        else {
            print("\(dirName) exists. Continuing..")
        }
    }
    catch{
        exit(1)
    }
    fm.changeCurrentDirectoryPath(relativePath)
    let doc = getHTMLFrom(url: finalURL)
    guard let body = doc.body() else {
        return
    }
    do {
        let table = try body.getElementsByTag("table").get(0)
        for tr in try table.getElementsByTag("tr") {
            var item_type = ""
            var item_url = ""
            for td in try tr.getElementsByTag("td") {
                if try td.className() == "fb-i" {
                    let img = try td.getElementsByTag("img").get(0)
                    item_type = try img.attr("alt")
                }
                if try td.className() == "fb-n" {
                    let a = try td.getElementsByTag("a").get(0)
                    item_url = try a.attr("href")
                }
            }
            if item_type == "file" {
                download(baseURL, item_url)
            }
            if item_type == "folder" {
                list(baseURL, path)
                fm.changeCurrentDirectoryPath("..")
            }
        }
    }
    catch{
        print("Remote dir: \(dirName) might be empty")
    }
}

func isFile(_ baseURL: String, _ path: String, _ item: String) -> Bool {
    var file = false
    let finalURL = "\(baseURL)\(path)"
    let doc = getHTMLFrom(url: finalURL)
    guard let body = doc.body() else {
        exit(1)
    }
    do {
        let table = try body.getElementsByTag("table").get(0)
        for tr in try table.getElementsByTag("tr") {
            for td in try tr.getElementsByTag("td") {
                if try td.className() == "fb-i" {
                    let img = try td.getElementsByTag("img").get(0)
                    file = try img.attr("alt") == "file"
                }
                if try td.className() == "fb-n" {
                    let a = try td.getElementsByTag("a").get(0)
                    if try a.text() == item {
                        return file
                    }
                }
            }
        }
        return file
    }
    catch{
        exit(1)
    }
}

func download(_ baseURL: String, _ Url: String) {
    if ariaIsAvailable() {
        oshell("aria2c", "-x", "1", "--auto-file-renaming=false", "--console-log-level=error", "--summary-interval=0", "\(baseURL)\(Url)")
    }
    else {
        print("please install aria2")
        exit(1)
    }
}

@discardableResult
func shell(_ command: String...) -> Int32 {
    let process = Process()
    let pipe = Pipe()
    process.launchPath = "/usr/bin/env"
    process.arguments = command
    process.standardOutput = pipe
    process.standardError = pipe
    process.standardInput = nil
    process.launch()
    process.waitUntilExit()
    return process.terminationStatus
}

@discardableResult
func oshell(_ command: String...) -> Int32 {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = command
    signal(SIGINT, SIG_IGN)
    let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT)
    sigintSource.setEventHandler {
        process.terminate()
        exit(0)
    }
    sigintSource.resume()
    do { try process.run() }
    catch {}
    process.waitUntilExit()
    return process.terminationStatus
}

func ariaIsAvailable() -> Bool {
    shell("aria2c", "-v") == 0
}

func getHTMLFrom(url: String) -> Document {
    
    guard let url = URL(string: url) else {
        exit(1)
    }
    do {
        let data = try Data(contentsOf: url)
        guard let html = String(data: data, encoding: .utf8) else {
            exit(1)
        }
        return try SwiftSoup.parse(html)
    }
    catch {
        exit(1)
    }
}

func getName(_ path: String) -> String {
    let pathComponents = path.split(separator: "/")
    let pathSize = pathComponents.count
    return String(pathComponents[pathSize - 1]).decodeUrl()
}

extension String {
    func decodeUrl() -> String {
        return self.removingPercentEncoding!
    }

    func parseURL() -> (String, String, String, String) {
        var splittedUrl = self.split(separator: "/").dropFirst()
        let urlDomain = splittedUrl.first!.description
        splittedUrl = splittedUrl.dropFirst()
        let path = "/\(splittedUrl.joined(separator: "/"))"
        let verifierPath = "/\(path.split(separator: "/").dropLast().joined(separator: "/"))"
        let filename = splittedUrl.last!.description.decodeUrl()
        return (urlDomain, path, filename, verifierPath)
    }
}