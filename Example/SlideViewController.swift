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
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let pager: UIPageControl = {
        let view = UIPageControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        SlidingPhotoViewCell.displayViewClass = AnimatedImageView.self

        super.viewDidLoad()
        
        slidingPhotoView.register(CustomPhotoViewCell.self)
//        slidingPhotoView.register(NibPhotoCell.nib)
        slidingPhotoView.scrollToItem(at: fromPage, animated: false)
        
        pager.numberOfPages = localUrls.count
        pager.currentPage = fromPage
        contentView.addSubview(pager)
        pager.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        if #available(iOS 11.0, *) {
            pager.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            pager.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor).isActive = true
        }
    }
    
    private lazy var statusBarWindow: UIView = UIApplication.shared.value(forKey: "statusBarWindow") as! UIView
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UIScreen.main.isNotchExist {
            return
        }
        
        UIView.animate(withDuration: 0.25) {
            self.statusBarWindow.transform = CGAffineTransform(translationX: 0, y: -UIApplication.shared.statusBarFrame.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if UIScreen.main.isNotchExist {
            return
        }
        
        UIView.animate(withDuration: 0.25) {
            self.statusBarWindow.transform = .identity
        }
    }
    
    override func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int {
        return localUrls.count
    }
    
    override func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, prepareForDisplay cell: SlidingPhotoViewCell) {
        let cell = cell as! CustomPhotoViewCell
        let url = UserDefaults.standard.loadOnlineImages ? remoteUrls[cell.index] : localUrls[cell.index]
        if let imageView = cell.displayView as? UIImageView {
            imageView.kf.setImage(with: url, placeholder: imageView.image, options: [.backgroundDecode, .transition(.none)], progressBlock: { [weak cell] (current, total) in
                let progress = CGFloat(current) / CGFloat(total)
                let displayProgress = progress - 0.1 > 0 ? progress - 0.1 : progress
                cell?.progressLayer.strokeEnd = displayProgress
                cell?.progressLayer.isHidden = false
            }) { [weak cell] (image, error, cache, url) in
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
            let rect = displayView.convert(displayView.frame, to: cell)
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

extension UIScreen {
    public var isNotchExist: Bool {
        switch UIScreen.main.nativeBounds.size {
        case CGSize(width: 1125, height: 2436),
             CGSize(width: 1242, height: 2688),
             CGSize(width: 828, height: 1792):
            return true
        default:
            return false
        }
    }
}
