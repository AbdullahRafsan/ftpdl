// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

let arguments = CommandLine.arguments.dropFirst()

guard let url = arguments.first else {
    print("Expected a folder. Aborting")
    exit(1)
}
let (urlDomain, path, filename, verifierPath) = url.parseURL()

print("URL: \(url)")
print("URL Domain: \(urlDomain)")
print("Path: \(path)")
print("Filename: \(filename)")
print("Verifier path: \(verifierPath)")

if TIMEPASSBD_URL.contains(urlDomain) {
    let isFile = isFile(TIMEPASSBD_URL, verifierPath, filename)
    if isFile {
        download(TIMEPASSBD_URL, path)
    }
    else {
        list(TIMEPASSBD_URL, path)
    }
}
else {
    print("Unrecognized url")
    exit(1)
}