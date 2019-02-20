//
//  ViewController.swift
//  FolderManager
//
//  Created by Feialoh Francis on 10/10/18.
//  Copyright © 2018 Feialoh Francis. All rights reserved.
//

import Cocoa

public enum LogType: Int {
    
    case rename
    case create
    case error
    
}

class ViewController: NSViewController {
    
    
    @IBOutlet weak var selectedDirectoryLabel: NSTextField!
    
    
    @IBOutlet weak var filterText: NSTextField!
    
    @IBOutlet weak var filterText2: NSTextField!
    
    @IBOutlet weak var hintLabel: NSTextField!
    
    @IBOutlet weak var hintLabel2: NSTextField!
    
    
    @IBOutlet weak var logScrollView: NSScrollView!
    
    
    @IBOutlet var logTextView: NSTextView!
    
    @IBOutlet weak var currentSelectionLabel: NSTextField!
    
    @IBOutlet weak var summaryLabel: NSTextField!
    
    
    var stripFileCount = 0
    var createdFolderCount = 0
    var errorCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        hintLabel.stringValue = "Eg: Filename: \"Deadpool (2018) HDrip YIFY\", Entering filter string: \")\" gives you-> Deadpool (2018)"
        
        hintLabel2.stringValue = "Eg: Filename: \"01 My Song\", Entering filter string: \"01 \" gives you-> My Song"
        
        currentSelectionLabel.isHidden = true

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func clearLogsAction(_ sender: Any) {
        
        logTextView.string = ""
        summaryLabel.stringValue = "Summary : "
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
                currentSelectionLabel.isHidden = false
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    

    @IBAction func createFoldersForFiles(_ sender: Any) {
        
        createdFolderCount = 0
        stripFileCount = 0
        errorCount = 0
        if !selectedDirectoryLabel.stringValue.isEmpty {
            processFiles(selectedDirectoryLabel.stringValue)
        }else {
            showAlert(title: "Error", message: "Please select a folder")
        }
    }
    
    
    @IBAction func stripFileNames(_ sender: Any) {

        createdFolderCount = 0
        stripFileCount = 0
        errorCount = 0
        if !filterText.stringValue.isEmpty {
            stripFileNames(filterText.stringValue, selectedDirectory: selectedDirectoryLabel.stringValue)
        } else {
            showAlert(title: "Error", message: "Please enter filter string")
        }
        
    }
    
    @IBAction func stripFilenameFromStart(_ sender: Any) {
        createdFolderCount = 0
        stripFileCount = 0
        errorCount = 0
        if !filterText2.stringValue.isEmpty {
            stripFileNamesFromStart(filterText2.stringValue, selectedDirectory: selectedDirectoryLabel.stringValue)
        } else {
            showAlert(title: "Error", message: "Please enter filter string")
        }
    }
    
    
    @IBAction func renameFilesInOrder(_ sender: Any) {
        createdFolderCount = 0
        stripFileCount = 0
        errorCount = 0
        if !selectedDirectoryLabel.stringValue.isEmpty {
            processFilesForRenaming(selectedDirectoryLabel.stringValue)
        }else {
            showAlert(title: "Error", message: "Please select a folder")
        }
    }
    
    
    /// To create folders
    ///
    /// - Parameter folderPath: Selected directory
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
//                               logTextView.string.append(contentsOf: "Created Folder at -> \(newFolderPath.path)\n")
                                addLogsToView("Created Folder at -> \(newFolderPath.path)\n", logType: .create)
                               let destinationPath = newFolderPath.appendingPathComponent(url.lastPathComponent)
                                renameMove( url, destinationURL: destinationPath)
                                createdFolderCount += 1
                                
                            }
                        }
                    }
                    else {
                        print("Nothing selected")
                    }
                }
                
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: selectedDirectoryLabel.stringValue)
                summary()
                
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
                
                addLogsToView("Error while enumerating files \(folderURL.path): \(error.localizedDescription)", logType: .error)
                errorCount += 1
            }
        }

    }
    
    
    func processFilesForRenaming(_ selectedDirectory:String){
        
        let fileManager = FileManager.default
        
        let folderURL = URL(fileURLWithPath: selectedDirectory)
        
        
        
        if (folderURL.isFileURL) {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options:[.skipsHiddenFiles])
                let zeroCount = "\(fileURLs.count)".count
                
               let sortedURLs = fileURLs.sorted(by: { (Obj1, Obj2) -> Bool in
                let Obj1_Name = Obj1.absoluteString
                let Obj2_Name = Obj2.absoluteString
                    return (Obj1_Name.localizedCaseInsensitiveCompare(Obj2_Name) == .orderedAscending)
                })
                
//                let sortedURLs = fileURLs.absoluteString.sorted(by: <)
                // process files
                for (index,url) in sortedURLs.enumerated() {
                    let formatted = String(format: "%0\(zeroCount)d.", index+1)
                    
                    var isDir: ObjCBool = false
                    
                    if (fileManager.fileExists(atPath: url.path, isDirectory: &isDir)) {
                        
                        let fileName = isDir.boolValue ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
                        
                        let strippedFileName = "\(formatted)\(fileName)"
                        print("New name:\(strippedFileName)")
                            var desinationPath = folderURL.appendingPathComponent(String(strippedFileName))
                            if !isDir.boolValue{
                                desinationPath = (folderURL.appendingPathComponent(String(strippedFileName))).appendingPathExtension(url.pathExtension)
                                if url != desinationPath {
                                    renameMove(url, destinationURL: desinationPath)
                                    stripFileCount += 1
                                }
                            } else if isDir.boolValue {
                                
                                if url != desinationPath {
                                    renameMove(url, destinationURL: desinationPath)
                                    stripFileCount += 1
                                    stripFileNames(filterText.stringValue, selectedDirectory: desinationPath.relativePath)
                                }
                            }
                        
                        
                    }
                    else {
                        
                        //                        showAlert(title: "Error", message: "File Doesn't Exist")
                        errorCount += 1
                        
                    }
                }
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: selectedDirectoryLabel.stringValue)
                summary()
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
            }
        }
        
    }
    
    
    /// To strip file names
    ///
    /// - Parameter filterString: string strip filter
    func stripFileNames(_ filterString:String, selectedDirectory:String){
        
        let fileManager = FileManager.default
        
        let folderURL = URL(fileURLWithPath: selectedDirectory)
        
        if (folderURL.isFileURL) {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options:[.skipsHiddenFiles])
                // process files
                for url in fileURLs {
                    var isDir: ObjCBool = false
                    
                    if (fileManager.fileExists(atPath: url.path, isDirectory: &isDir)) {
                        
                        let fileName = isDir.boolValue ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
                        
                        if let rangeOfFilter = fileName.range(of: filterString) {
                            let strippedFileName = fileName[..<rangeOfFilter.upperBound]
                            
                            var desinationPath = folderURL.appendingPathComponent(String(strippedFileName))
                            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as CFString, nil)
                            if !isDir.boolValue && UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeMovie){
                                desinationPath = (folderURL.appendingPathComponent(String(strippedFileName))).appendingPathExtension(url.pathExtension)
                                if url != desinationPath {
                                    renameMove(url, destinationURL: desinationPath)
                                    stripFileCount += 1
                                }
                            } else if isDir.boolValue {
                                
                                if url != desinationPath {
                                    renameMove(url, destinationURL: desinationPath)
                                    stripFileCount += 1
                                    stripFileNames(filterText.stringValue, selectedDirectory: desinationPath.relativePath)
                                }
                            }
                        }
                        
                    }
                    else {
                        
//                        showAlert(title: "Error", message: "File Doesn't Exist")
                        errorCount += 1
                        
                    }
                }
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: selectedDirectoryLabel.stringValue)
                summary()
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
            }
        }
        
    }
    
    func stripFileNamesFromStart(_ filterString:String, selectedDirectory:String){
        
        let fileManager = FileManager.default
        
        let folderURL = URL(fileURLWithPath: selectedDirectory)
        
        if (folderURL.isFileURL) {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options:[.skipsHiddenFiles])
                // process files
                for url in fileURLs {
                    var isDir: ObjCBool = false
                    
                    if (fileManager.fileExists(atPath: url.path, isDirectory: &isDir)) {
                        
                        let fileName = isDir.boolValue ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
                        
                        var strippedFileName = isDir.boolValue ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
                        
                        
                        if let rangeOfFilter = fileName.range(of: filterString) {
                            
                           strippedFileName.replaceSubrange(rangeOfFilter, with: "")
//                            let strippedFileName = fileName[..<rangeOfFilter.upperBound]
                            print("New name:\(strippedFileName)")
                            var desinationPath = folderURL.appendingPathComponent(String(strippedFileName))
                            if !isDir.boolValue{
                                desinationPath = (folderURL.appendingPathComponent(String(strippedFileName))).appendingPathExtension(url.pathExtension)
                                if url != desinationPath {
                                    renameMove(url, destinationURL: desinationPath)
                                    stripFileCount += 1
                                }
                            } else if isDir.boolValue {
                                
                                if url != desinationPath {
                                    renameMove(url, destinationURL: desinationPath)
                                    stripFileCount += 1
                                    stripFileNames(filterText.stringValue, selectedDirectory: desinationPath.relativePath)
                                }
                            }
                        }
                        
                    }
                    else {
                        
                        //                        showAlert(title: "Error", message: "File Doesn't Exist")
                        errorCount += 1
                        
                    }
                }
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: selectedDirectoryLabel.stringValue)
                summary()
            } catch {
                print("Error while enumerating files \(folderURL.path): \(error.localizedDescription)")
            }
        }
    }
    
    
    /// Renaming/Moving files
    ///
    /// - Parameters:
    ///   - fileURL: original file location
    ///   - destinationURL: new file location with name
    func renameMove(_ fileURL:URL, destinationURL:URL) {
        
        do {
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        print("Changed: \(fileURL.path) to \(destinationURL.path) ")
        
//        logTextView.string.append(contentsOf: "Changed: \(fileURL.path) to \(destinationURL.path)\n")

        addLogsToView("Changed: \(fileURL.path) to \(destinationURL.path)\n", logType: .rename)
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

    
    /// Adding logs of the operations
    ///
    /// - Parameters:
    ///   - logs: Log strings
    ///   - logType: log type
    func addLogsToView(_ logs:String, logType:LogType){
        
        var textColor = NSColor(hexString: "c60714")!
        
        switch logType {
        case .rename:
                textColor = NSColor(hexString: "1458a0")!
        case .create:
                textColor = NSColor(hexString: "087a47")!
        default:
            break
        }
        
        
        let attributes = [NSAttributedString.Key.foregroundColor: textColor]
        let attrStr = NSMutableAttributedString(string: logs, attributes: attributes)
        logTextView.textStorage?.append(attrStr)
    }
    
    
    /// Summary of the result
    func summary() {
        
        summaryLabel.stringValue = "Summary : "
        var summaryString = ""
        var errorString = ""
        
        if (createdFolderCount == 0) && (stripFileCount == 0) {
            summaryString = "No files were modified."
        } else if (createdFolderCount > 0) {
            summaryString = (createdFolderCount == 1) ? "\(createdFolderCount) folder created." : "\(createdFolderCount) folder's were created."
           
        } else if (stripFileCount > 0) {
            summaryString = (stripFileCount == 1) ? "\(stripFileCount) file/folder renamed" : "\(stripFileCount) file's/folder's were renamed."
        }
        
         summaryLabel.stringValue.append(contentsOf: summaryString)
        
        errorString = (errorCount > 0) ? " \(errorCount) error occurred." : " No errors."
        
        summaryLabel.stringValue.append(contentsOf: errorString)
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
        return folderURL
    }
}


extension NSColor {
    ///init method with hex string and alpha(default: 1)
    public convenience init?(hexString: String, alpha: CGFloat = 1.0) {
        var formatted = hexString.replacingOccurrences(of: "0x", with: "")
        formatted = formatted.replacingOccurrences(of: "#", with: "")
        if let hex = Int(formatted, radix: 16) {
            let red = CGFloat(CGFloat((hex & 0xFF0000) >> 16)/255.0)
            let green = CGFloat(CGFloat((hex & 0x00FF00) >> 8)/255.0)
            let blue = CGFloat(CGFloat((hex & 0x0000FF) >> 0)/255.0)
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return nil
        }
    }
    
}
