//
//  DITableViewController.swift
//  DocInteraction
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/1/17.
//
//
/*
     File: DITableViewController.h
     File: DITableViewController.m
 Abstract: The table view that display docs of different types.
  Version: 1.6

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2014 Apple Inc. All Rights Reserved.

 */

import UIKit
import QuickLook

let documents: [String] = [
    "Text Document.txt",
    "Image Document.jpg",
    "PDF Document.pdf",
    "HTML Document.html"
]

let kRowHeight: CGFloat = 58.0

//MARK: -

@objc(DITableViewController)
class DITableViewController: UITableViewController, QLPreviewControllerDataSource,
    QLPreviewControllerDelegate,
    DirectoryWatcherDelegate,
UIDocumentInteractionControllerDelegate {
    
    private var docWatcher: DirectoryWatcher!
    private var documentURLs: [NSURL] = []
    private var docInteractionController: UIDocumentInteractionController!
    
    //MARK: -
    
    private func setupDocumentControllerWithURL(url: NSURL) {
        //checks if docInteractionController has been initialized with the URL
        if self.docInteractionController == nil {
            self.docInteractionController = UIDocumentInteractionController(URL: url)
            self.docInteractionController.delegate = self
        } else {
            self.docInteractionController.URL = url
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start monitoring the document directory…
        self.docWatcher = DirectoryWatcher.watchFolderWithPath(self.applicationDocumentsDirectory, delegate: self)
        
        // scan for existing documents
        self.directoryDidChange(self.docWatcher)
    }
    
    //- (void)viewDidUnload
    //{
    //    self.documentURLs = nil;
    //    self.docWatcher = nil;
    //}
    
    // if we installed a custom UIGestureRecognizer (i.e. long-hold), then this would be called
    
    func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        if longPressGesture.state == .Began {
            let cellIndexPath = self.tableView.indexPathForRowAtPoint(longPressGesture.locationInView(self.tableView))!
            
            var fileURL: NSURL
            if cellIndexPath.section == 0 {
                // for section 0, we preview the docs built into our app
                fileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(documents[cellIndexPath.row], ofType: nil)!)
            } else {
                // for secton 1, we preview the docs found in the Documents folder
                fileURL = self.documentURLs[cellIndexPath.row]
            }
            self.docInteractionController.URL = fileURL
            
            self.docInteractionController.presentOptionsMenuFromRect(longPressGesture.view!.frame, inView: longPressGesture.view!, animated: true)
        }
    }
    
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Initializing each section with a set of rows
        if section  == 0 {
            return documents.count
        } else {
            return self.documentURLs.count
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String? = nil
        // setting headers for each section
        if section == 0 {
            title = "Example Documents"
        } else {
            if self.documentURLs.count > 0 {
                title = "Documents folder"
            }
        }
        
        return title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "cellID"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell?
        
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
            cell!.accessoryType = .DisclosureIndicator
        }
        
        var fileURL: NSURL
        
        if indexPath.section == 0 {
            // first section is our build-in documents
            fileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(documents[indexPath.row], ofType: nil)!)
        } else {
            // second section is the contents of the Documents folder
            fileURL = self.documentURLs[indexPath.row]
        }
        self.setupDocumentControllerWithURL(fileURL)
        
        // layout the cell
        cell!.textLabel?.text = fileURL.lastPathComponent
        let iconCount = self.docInteractionController.icons.count
        if iconCount > 0 {
            cell!.imageView?.image = self.docInteractionController.icons[iconCount - 1]
        }
        
        let fileURLString = self.docInteractionController.URL!.path!
        let fileAttributes = try! NSFileManager.defaultManager().attributesOfItemAtPath(fileURLString)
        let fileSize = (fileAttributes[NSFileSize] as! NSNumber).longLongValue
        let fileSizeStr = NSByteCountFormatter.stringFromByteCount(fileSize,
            
            countStyle: NSByteCountFormatterCountStyle.File)
        let uti = self.docInteractionController.UTI ?? ""
        cell!.detailTextLabel?.text = "\(fileSizeStr) - \(uti)"
        
        // attach to our view any gesture recognizers that the UIDocumentInteractionController provides
        //cell.imageView.userInteractionEnabled = YES;
        //cell.contentView.gestureRecognizers = self.docInteractionController.gestureRecognizers;
        //
        // or
        // add a custom gesture recognizer in lieu of using the canned ones
        //
        let longPressGesture =
        UILongPressGestureRecognizer(target: self, action: #selector(DITableViewController.handleLongPress(_:)))
        cell!.imageView?.addGestureRecognizer(longPressGesture)
        cell!.imageView?.userInteractionEnabled = true
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kRowHeight
    }
    
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // three ways to present a preview:
        // 1. Don't implement this method and simply attach the canned gestureRecognizers to the cell
        //
        // 2. Don't use canned gesture recognizers and simply use UIDocumentInteractionController's
        //      presentPreviewAnimated: to get a preview for the document associated with this cell
        //
        // 3. Use the QLPreviewController to give the user preview access to the document associated
        //      with this cell and all the other documents as well.
        
        // for case 2 use this, allowing UIDocumentInteractionController to handle the preview:
        /*
        NSURL *fileURL;
        if (indexPath.section == 0)
        {
        fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:documents[indexPath.row] ofType:nil]];
        }
        else
        {
        fileURL = [self.documentURLs objectAtIndex:indexPath.row];
        }
        [self setupDocumentControllerWithURL:fileURL];
        [self.docInteractionController presentPreviewAnimated:YES];
        */
        
        // for case 3 we use the QuickLook APIs directly to preview the document -
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        
        // start previewing the document at the current section index
        previewController.currentPreviewItemIndex = indexPath.row
        self.navigationController?.pushViewController(previewController, animated: true)
    }
    
    
    //MARK: - UIDocumentInteractionControllerDelegate
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    
    //MARK: - QLPreviewControllerDataSource
    
    // Returns the number of items that the preview controller should preview
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        var numToPreview = 0
        
        let selectedIndexPath = self.tableView.indexPathForSelectedRow
        if (selectedIndexPath?.section ?? 0) == 0 {
            numToPreview = documents.count
        } else {
            numToPreview = self.documentURLs.count
        }
        
        return numToPreview
    }
    
    func previewControllerDidDismiss(controller: QLPreviewController) {
        // if the preview dismissed (done button touched), use this method to post-process previews
    }
    
    // returns the item that the preview controller should preview
    func previewController(controller: QLPreviewController, previewItemAtIndex idx: Int) -> QLPreviewItem {
        var fileURL: NSURL
        
        let selectedIndexPath = self.tableView.indexPathForSelectedRow
        if (selectedIndexPath?.section ?? 0) == 0 {
            fileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(documents[idx], ofType: nil)!)
        } else {
            fileURL = self.documentURLs[idx]
        }
        
        return fileURL
    }
    
    
    //MARK: - File system support
    
    private var applicationDocumentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last! as String
    }
    
    func directoryDidChange(folderWatcher: DirectoryWatcher) {
        self.documentURLs.removeAll(keepCapacity: true)
        
        let documentsDirectoryPath = self.applicationDocumentsDirectory
        
        let documentsDirectoryContents: [AnyObject]?
        do {
            documentsDirectoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentsDirectoryPath)
        } catch _ {
            documentsDirectoryContents = nil
        }
        
        for curFileName in documentsDirectoryContents! as! [String] {
            let filePath = (documentsDirectoryPath as NSString).stringByAppendingPathComponent(curFileName)
            let fileURL = NSURL(fileURLWithPath: filePath)
            
            var isDirectory: ObjCBool = false
            NSFileManager.defaultManager().fileExistsAtPath(filePath, isDirectory: &isDirectory)
            
            // proceed to add the document URL to our list (ignore the "Inbox" folder)
            if !isDirectory && curFileName == "Inbox" {
                self.documentURLs.append(fileURL)
            }
        }
        
        self.tableView.reloadData()
    }
    
}