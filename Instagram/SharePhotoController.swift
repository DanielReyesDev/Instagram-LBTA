//
//  SharePhotoController.swift
//  Instagram
//
//  Created by Daniel Reyes Sánchez on 16/09/17.
//  Copyright © 2017 Daniel Reyes Sánchez. All rights reserved.
//

import UIKit
import Firebase

class SharePhotoController: UIViewController {
    
    var selectedImage:UIImage? {
        didSet {
            self.imageView.image = selectedImage
        }
    }
    
    let imageView:UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .red
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        return tv
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.rbg(240, 240, 240)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        setupImageAndTextViews()
    }
    
    
    fileprivate func setupImageAndTextViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        containerView.anchor(top: topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 0, width: 0, height: 100)
        
        containerView.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: nil, paddingTop: 8, paddingLeft: 8, paddingRight: 0, paddingBottom: 8, width: 84, height: 0)
        
        containerView.addSubview(textView)
        textView.anchor(top: containerView.topAnchor, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 4, paddingRight: 0, paddingBottom: 0, width: 0, height: 0)
    }
    
    func handleShare() {
        guard let caption = textView.text, caption.characters.count > 0 else {return}
        guard let image = selectedImage else { return }
        guard let uploadData = UIImageJPEGRepresentation(image, 0.5) else {return}
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let filename = NSUUID().uuidString
        
        FIRStorage.storage().reference().child("posts").child(filename).put(uploadData, metadata: nil) { (metadata:FIRStorageMetadata?, err:Error?) in
            if let err = err {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to upload post image", err.localizedDescription)
                return
            }
            guard let imageUrl = metadata?.downloadURL()?.absoluteString else {return}
            
            print("Successfully upload post image: ",imageUrl)
            
            self.saveToDatabaseWithImageUrl(imageUrl: imageUrl)
            
            
        }
    }
    
    static let updateFeedNotificationName = NSNotification.Name(rawValue:"UpdateFeed")
    
    fileprivate func saveToDatabaseWithImageUrl(imageUrl: String) {
        guard let postImage = selectedImage else {return}
        guard let caption = textView.text else {return}
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
    
        let userPostRef = FIRDatabase.database().reference().child("posts").child(uid)
        let ref = userPostRef.childByAutoId()
        let values = ["imageUrl":imageUrl,
                      "caption":caption,
                      "imageWidth":postImage.size.width,
                      "imageHeight":postImage.size.height,
                      "creationDate":Date().timeIntervalSince1970] as [String : Any]
        
        ref.updateChildValues(values) { (error: Error?, reference:FIRDatabaseReference) in
            if let err = error {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                print("Failed to post to DB ", err.localizedDescription)
                return
            }
            
            print("Successfully saved to DB")
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: SharePhotoController.updateFeedNotificationName, object: nil)
        }
    }
}
