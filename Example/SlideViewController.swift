//
//  SlideViewController.swift
//  Example
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit
import SlidingPhoto
import Kingfisher

class SlideViewController: SlidingPhotoViewController {
    private lazy var remoteUrls: [URL] = {
        return (0..<10).map({ URL(string: "https://github.com/cuzv/SlidingPhoto/raw/master/Example/Images.bundle/image-\($0).jpg")! })
    }()
    
    private lazy var localUrls: [URL] = {
        let bundlePath = Bundle(for: type(of: self)).path(forResource: "Images", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        let paths = (0..<10).map({ bundle.path(forResource: "image-\($0)", ofType: "jpg")! })
        return paths.map({ URL(fileURLWithPath: $0) })
    }()
    
    private let vc: PhotosViewController
    private let fromPage: Int
    init(from vc: PhotosViewController, fromPage: Int) {
        self.vc = vc
        self.fromPage = fromPage
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let pager: UIPageControl = {
        let view = UIPageControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override func viewDidLoad() {
        SlidingPhotoViewCell.displayViewClass = ExampleAnimatedImageView.self

        super.viewDidLoad()
        
        slidingPhotoView.register(CustomPhotoViewCell.self)
//        slidingPhotoView.register(NibPhotoCell.nib)
        slidingPhotoView.scrollToItem(at: fromPage, animated: false)
//        slidingPhotoView.panGestureRecognizer.isEnabled = false
        
        pager.numberOfPages = localUrls.count
        pager.currentPage = fromPage
        view.addSubview(pager)
        pager.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        if #available(iOS 11.0, *) {
            pager.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            pager.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        }
    }
    
    override func willDismissByPanGesture() {
        print("willDismissByPanGesture")
    }
    
    override func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int {
        return localUrls.count
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, prepareForDisplay cell: SlidingPhotoViewCell) {
        let cell = cell as! CustomPhotoViewCell
        let url = UserDefaults.standard.loadOnlineImages ? remoteUrls[cell.index] : localUrls[cell.index]
        if let imageView = cell.displayView as? UIImageView {
            imageView.kf.setImage(with: url, options: []) { [weak cell] (current, total) in
                let progress = (CGFloat(current) / CGFloat(total)).nanToZero()
                let displayProgress = progress - 0.1 > 0 ? progress - 0.1 : progress
                cell?.progressLayer.strokeEnd = displayProgress
                cell?.progressLayer.isHidden = false
            } completionHandler: { [weak cell] (result: Result<RetrieveImageResult, KingfisherError>) in
                cell?.progressLayer.strokeEnd = 1
                cell?.progressLayer.isHidden = true
            }
        }
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, thumbnailForTransition cell: SlidingPhotoViewCell) -> SlidingPhotoDisplayView? {
        return (vc.collectionView.cellForItem(at: IndexPath(item: cell.index, section: 0)) as? PhotoCollectionViewCell)?.imageView
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTapped cell: SlidingPhotoViewCell, at location: CGPoint) {
        if cell.isContentZoomed {
           cell.isContentZoomed.toggle()
        }
        
        if cell.index == 1 { // GIF
            let displayView = cell.displayView as! AnimatedImageView
            let rect = displayView.convert(displayView.bounds, to: cell)
            if rect.contains(location) {
                if displayView.isAnimating {
                    displayView.stopAnimating()
                } else {
                    displayView.startAnimating()
                }
                return
            }
        }
        
        vc.focusToCellAtIndexPath(IndexPath(item: cell.index, section: 0), at: cell.index > fromPage ? .bottom : .top)
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdateFocus cell: SlidingPhotoViewCell) {
        pager.currentPage = cell.index
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didEndDisplaying cell: SlidingPhotoViewCell) {
        cell.displayView.image = nil
        
        if let cell = cell as? CustomPhotoViewCell {
            cell.progressLayer.isHidden = true
            cell.progressLayer.strokeEnd = 0
        }
    }
}

final class ExampleAnimatedImageView: AnimatedImageView {
    override var isHighlighted: Bool {
        get { super.isHighlighted }
        set {}
    }
}
