//
//  PhotosViewController.swift
//  Example
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit
import Kingfisher

private let reuseIdentifier = "PhotoCell"

extension UserDefaults {
    var loadOnlineImages: Bool {
        get {
            return bool(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
}

class PhotosViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private lazy var remoteUrls: [URL] = {
        return (0..<10).map({ URL(string: "https://github.com/cuzv/SlidingPhoto/raw/master/Example/Images.bundle/image-small-\($0).jpg")! })
    }()
    
    private lazy var localUrls: [URL] = {
        let bundlePath = Bundle(for: type(of: self)).path(forResource: "Images", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        let paths = (0..<10).map({ bundle.path(forResource: "image-small-\($0)", ofType: "jpg")! })
        return paths.map({ URL(fileURLWithPath: $0) })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadImageSettingSwitch.isOn = UserDefaults.standard.loadOnlineImages
    }
    
    @IBOutlet weak var loadImageSettingSwitch: UISwitch!
    @IBAction func handleClickClearCache(_ sender: UIBarButtonItem) {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
        collectionView.reloadData()
    }
    
    @IBAction func toggleLoadOnlineImages(_ sender: UISwitch) {
        UserDefaults.standard.loadOnlineImages = sender.isOn
        collectionView.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return localUrls.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        // Rather important
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let url = UserDefaults.standard.loadOnlineImages ? remoteUrls[indexPath.item] : localUrls[indexPath.item]
        cell.imageView.kf.setImage(with: url, completionHandler:  { [weak cell] (image, error, cacheType, url) in
            cell?.imageView.sp.image = image
        })
        
        cell.layer.borderColor = UIColor.cyan.cgColor
        cell.layer.borderWidth = 1
        
        return cell
    }
    
    func focusToCellAtIndexPath(_ indexPath: IndexPath, at position: UICollectionView.ScrollPosition) {
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            collectionView.scrollToItem(at: indexPath, at: position, animated: false)
        }
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = floor((collectionView.bounds.width - 24) / 2.0)
        if indexPath.item == 2 || indexPath.item == 3 {
            return CGSize(width: side, height: side * 0.8)
        }
        if indexPath.item == 4 || indexPath.item == 5 {
            return CGSize(width: side, height: side * 1.2)
        }
        return CGSize(width: side, height: side)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = SlideViewController(from: self, fromPage: indexPath.item)
        present(vc, animated: true, completion: nil)
    }
}

// MARK: - PhotoCollectionViewCell

final class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sp.image = nil
    }
}
