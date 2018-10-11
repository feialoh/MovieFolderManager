//
//  ViewController.swift
//  FolderManager
//
//  Created by Feialoh Francis on 10/10/18.
//  Copyright © 2018 Feialoh Francis. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    
    @IBOutlet weak var selectedDirectoryLabel: NSTextField!
    
    
    @IBOutlet weak var filterText: NSTextField!
    
    
    @IBOutlet weak var hintLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        hintLabel.stringValue = "Eg: Filename: Deadpool (2018) HDrip YIFY, Entering filter string: \")\" gives you-> Deadpool (2018)"
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func browseDirectory(_ sender: Any) {
        
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose a folder"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.canChooseFiles          = false
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                selectedDirectoryLabel.stringValue = path
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    

    @IBAction func createFoldersForFiles(_ sender: Any) {
        
        if !selectedDirectoryLabel.stringValue.isEmpty {
            processFiles(selectedDirectoryLabel.stringValue)
        }
    }
    
    
    @IBAction func stripFileNames(_ sender: Any) {

        if !filterText.stringValue.isEmpty {
            stripFileNames(filterText.stringValue)
        } else {
            showAlert(title: "Error", message: "Please enter filter string")
        }
        
    }
    
    func processFiles(_ folderPath:String){
        
        let fileManager = FileManager.default
        
        let folderURL = URL(fileURLWithPath: folderPath)
        
        
        if (folderURL.isFileURL) {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                // process files
                for url in fileURLs {
                    var isDir: ObjCBool = false
                    
                    if (fileManager.fileExists(atPath: url.path, isDirectory: &isDir)) {
                        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)
                        if !isDir.boolValue && UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMovie){
                            print("It's a file path:\(url.lastPathComponent)")
                            if let newFolderPath = URL.createFolder(folderName: url.deletingPathExtension().lastPathComponent, folderPath: folderURL)
                            {
                               let destinationPath = newFolderPath.appendingPathComponent(url.lastPathComponent)
                                renameMove( url, destinationURL: destinationPath)
                                
                            }
                        }
                    }
                    else {
                        print("Nothing selected")
                    }
                }
                
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderPath)
                
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
            }
        }

    }
    
    
    func stripFileNames(_ filterString:String){
        
        let fileManager = FileManager.default
        
        let folderURL = URL(fileURLWithPath: selectedDirectoryLabel.stringValue)
        
        if (folderURL.isFileURL) {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options:[.skipsHiddenFiles])
                // process files
                for url in fileURLs {
                    var isDir: ObjCBool = false
                    
                    if (fileManager.fileExists(atPath: url.path, isDirectory: &isDir)) {
                        
                        let fileName = url.deletingPathExtension().lastPathComponent
                        
                        if let rangeOfFilter = fileName.range(of: filterString) {
                            let strippedFileName = fileName[..<rangeOfFilter.upperBound]
                            
                            var desinationPath = folderURL.appendingPathComponent(String(strippedFileName))
                            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)
                            if !isDir.boolValue && UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMovie){
                                desinationPath = (folderURL.appendingPathComponent(String(strippedFileName))).appendingPathExtension(url.pathExtension)
                                renameMove(url, destinationURL: desinationPath)
                            } else if isDir.boolValue {
                                renameMove(url, destinationURL: desinationPath)
                            }
                        }
                        
                    }
                    else {
                        
                        showAlert(title: "Error", message: "File Doesn't Exist")
                    }
                }
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
            }
        }
        
    }
    
    
    func renameMove(_ fileURL:URL, destinationURL:URL) {
        
        do {
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        print("Changed: \(fileURL.path) to \(destinationURL.path) ")

    }
    
    @discardableResult
    func showAlert(title: String, message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }

    
}

extension URL {
    static func createFolder(folderName: String, folderPath:URL) -> URL? {
        let fileManager = FileManager.default
        let folderURL = folderPath.appendingPathComponent(folderName)
        // If folder URL does not exist, create it
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                // Attempt to create folder
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription + ":\(folderURL.path)")
                return nil
            }
        }
        print("Created Folder at -> \(folderURL.path)")
        return folderURL
    }
}


