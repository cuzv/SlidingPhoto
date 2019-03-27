//
//  UIView+SlidingPhoto.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/17/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

public final class SlidingPhoto<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol SlidingPhotoCompatible {
    associatedtype CompatibleType
    var sp: CompatibleType { get }
}

extension SlidingPhotoCompatible {
    public var sp: SlidingPhoto<Self> {
        return SlidingPhoto(self)
    }
}

// MARK: - 

extension SlidingPhoto where Base: UIView {
    public var image: UIImage? {
        get {
            let contents = base.layer.contents
            if nil == contents {
                return nil
            } else {
                return UIImage(cgImage: contents as! CGImage)
            }
        }
        set {
            setImage(newValue) { image in
                base.layer.contents = image?.cgImage
            }
        }
    }
    
    func setImage(_ image: UIImage?, work: (_ image: UIImage?) -> Void) {
        work(image)
        
        if let image = image {
            let iw = image.size.width
            let ih = image.size.height
            let vw = base.bounds.width
            let vh = base.bounds.height
            // vh / vw = ih * ? / iw
            // ? = (vh * iw) / (vw * ih)
            let factor = (vh * iw) / (vw * ih)
            if factor.isNaN || factor > 1 {
                // image: w > h
                base.contentMode = .scaleAspectFill
                base.layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            } else {
                // image: h > w
                base.contentMode = .scaleToFill
                let y = factor < UIScreen.main.bounds.width / UIScreen.main.bounds.height ? 0 : (1.0 - factor) / 2.0
                base.layer.contentsRect = CGRect(x: 0, y: y, width: 1, height: factor)
            }
        }
    }
    
    public var isContentsClippedToTop: Bool {
        let contentsRect = base.layer.contentsRect
        return contentsRect.minY == 0 && contentsRect.height < 1
    }
}

extension SlidingPhoto where Base: UIImageView {
    public var image: UIImage? {
        get {
            return base.image
        }
        set {
            setImage(newValue) { image in
                base.image = image
            }
        }
    }
}

extension UIView: SlidingPhotoCompatible {}

// MARK: -

private var alphaKey: Void?
extension SlidingPhoto where Base: UIView {
    var alpha: CGFloat {
        get {
            return objc_getAssociatedObject(base, &alphaKey) as? CGFloat ?? base.alpha
        }
        set {
            objc_setAssociatedObject(base, &alphaKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
