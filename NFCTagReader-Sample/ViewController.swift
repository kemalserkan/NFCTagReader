//
//  ViewController.swift
//  NFCTagReader-Sample
//
//  Created by Kemal Serkan YILDIRIM on 6.02.2021.
//

import UIKit
import CoreNFC

class ViewController: UIViewController {

  var tagReaderSession: NFCTagReaderSession?
  var readedNFCTag : String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  @IBAction func scanNFCTag(_ sender: Any) {
    
    guard NFCReaderSession.readingAvailable else {
      let alertController = UIAlertController(
          title: "Scanning Not Supported",
          message: "This device doesn't support tag scanning.",
          preferredStyle: .alert
      )
      alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.present(alertController, animated: true, completion: nil)
      return
    }
    
    if #available(iOS 13.0, *) {
      tagReaderSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self)
      tagReaderSession?.alertMessage = "NFCTag Reader Hold the card back your iPhone"
      tagReaderSession?.begin()
    } else {
      // Fallback on earlier versions
    }
    
  }
  
  func showReadedNNFCTTag() {
    
    DispatchQueue.main.async {
      let alertController = UIAlertController(
          title: "Readed NFC Tag",
        message: self.readedNFCTag,
          preferredStyle: .alert
      )
      alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.present(alertController, animated: true, completion: nil)
    }
    
  }
  
}

extension ViewController: NFCTagReaderSessionDelegate {
  
  func tagRemovalDetect(_ tag: NFCTag) {
    self.tagReaderSession?.connect(to: tag) { (error: Error?) in
      if error != nil || !tag.isAvailable {
        
        self.tagReaderSession?.restartPolling()
        return
      }
      DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
        self.tagRemovalDetect(tag)
      })
    }
  }
  
  func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    
  }
  
  func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
    
  }
  
  func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
    if tags.count > 1 {
      tagReaderSession!.alertMessage = "More than 1 tags was found. Please present only 1 tag."
                //tagSession.restartPolling()
                self.tagRemovalDetect(tags.first!)
                return
            }
            
    var ndefTag: NFCNDEFTag
    var miFareTag : NFCMiFareTag
    switch tags.first! {
      case let .iso15693(tag):
        ndefTag = tag
      case let .miFare(tag):
        miFareTag = tag
      case .feliCa(_):
        break
      case .iso7816(_):
        break
      @unknown default:
        session.invalidate(errorMessage: "Tag not valid.")
        return
    }
    
    let tag = tags.first!
    tagReaderSession?.connect(to: tag, completionHandler: { [self] error in
            if case let .miFare(miFare) = tag {
                var byteData = [UInt8]()
                miFare.identifier.withUnsafeBytes { byteData.append(contentsOf: $0) }
                var uid = "0"
                byteData.forEach {
                    uid.append(String($0, radix: 16))
                }
                print("UID: \(uid)")
              self.readedNFCTag = String(uid)
              tagReaderSession?.alertMessage = "NFCTag Readed successfully!"
              self.showReadedNNFCTTag()
              self.tagReaderSession?.invalidate()
            }
        })
  }
  
  
}
