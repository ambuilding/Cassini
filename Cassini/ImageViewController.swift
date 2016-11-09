//
//  ImageViewController.swift
//  Cassini
//
//  Created by WangQi on 16/5/25.
//  Copyright © 2016年 WangQi. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    var imageURL: URL? {
        didSet {
            image = nil
            /*
             we'll postpone our (expensive) fetch
             until we know we're going to appear on screen
             (this below in the viewWillApear)
             otherwise why waste the resources?
 */
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    func fetchImage() {
        if let url = imageURL {
            /*
             fire up the spinner
             because we're about to fork something off on another thread
             */
            spinner?.startAnimating()
            /*
             put a closure on the "user initiated" system queue
             this closure does NSData(contentsOfURL:) which blocks
             waiting for network response
             it's fine for it to block the "user initiated" queue
             because that's a concurrent queue
             (so other closures on that queue can run concurrently even as this one's blocked)
             */
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                let contentsOfURL = try? Data(contentsOf: url) // blocks! can't be on main queue!
                
                /* 
                 now that we got the data from the network
                 we want to put it up in the UI
                 but we can only do that on the main queue
                 so we queue up a closure here to do that
                 */
                DispatchQueue.main.async {
                    /*
                     since it could take a long time to fetch the image data
                     we make sure here that the image we fetched 
                     is still the one this ImageViewController wants to display!
                     we must always think of these sorts of things
                     when programming asynchronously异步的
                     */
                    if url == self.imageURL {
                        if let imageData = contentsOfURL {
                            self.image = UIImage(data: imageData)
                            // image's set will stop the spinner animating
                        } else {
                            self.spinner?.stopAnimating()
                        }
                    } else {
                        // just so we can see in the console when this happens
                        print("Ignored data returned from url \(url)")
                    }
                }
            } // 取图片的同时，可以进行其它操作，比如返回到Navcon
        }
    }
    // 取图片，通过url，得到图片等数据，UIImage，解析数据
    
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size
            /*
             all three of the next lines of code 
             are necessary to make zooming work
             */
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    // zooming will not work if we don't implement
    // this UIScrollViewDelegate method
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    fileprivate var imageView = UIImageView()
    
    /*
     a little helper var
     it just makes sure things are kept in sync
     whenever we change the image we're displaying 
     it's purely to make our code look prettier elsewhere in this class
     */
    
    fileprivate var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating() // 取到图片以后停止spinner
        }
    }
    
    // MARK: View Controller Lifecycle
    
    /*
     we know we're going to go on screen in this method
     so we can no longer wait to fire off our (expensive) image fetch
     */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }

    /*
     note that we build some of our UI in the storyboard
     by dragging a UIScrollView out into our scene
     and we build some of it here by adding our UIImageView
     as a subview of the UIScrollView
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
        //imageURL = NSURL(string: DemoURL.Stanford)
    }
    
}
