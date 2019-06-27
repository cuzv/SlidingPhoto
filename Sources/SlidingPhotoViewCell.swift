//
//  SlidingPhotoViewCell.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class SlidingPhotoViewCell: UIView {
    public static var displayViewClass: SlidingPhotoDisplayView.Type = UIImageView.self
    
    open internal(set) var index: Int = -1
    internal var prepared: Bool = false {
        didSet {
            if prepared {
                alpha = 1
                superview?.bringSubviewToFront(self)
            } else {
                alpha = 0
                superview?.sendSubviewToBack(self)
            }
        }
    }
    
    let scrollView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.clipsToBounds = true
        view.scrollsToTop = true
        view.bounces = true
        view.bouncesZoom = true
        view.alwaysBounceVertical = false
        view.alwaysBounceHorizontal = false
        view.showsVerticalScrollIndicator = true
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.maximumZoomScale = 3
        view.minimumZoomScale = 1
        return view
    }()
    
    @objc dynamic public let displayView: SlidingPhotoDisplayView = {
        let view = SlidingPhotoViewCell.displayViewClass.init()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var observation: NSKeyValueObservation?

    deinit {
        if let observer = observation {
            observation = nil
            
            if #available(iOS 13, *) {
                // do nothings
            } else {
                removeObserver(observer, forKeyPath: "displayView.image")
            }
            
            observer.invalidate()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutContents()
    }
    
    private func setup() {
        clipsToBounds = true
        
        scrollView.frame = bounds
        scrollView.delegate = self
        addSubview(scrollView)
        
        displayView.frame = bounds
        scrollView.addSubview(displayView)

        observation = observe(\.displayView.image, options: [.new]) { (self, change) in
            if nil != change.newValue {
                self.layoutContents()
            }
        }
    }
    
    private func layoutContents() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        scrollView.zoomScale = 1
        scrollView.frame = bounds.nanToZero()
        
        let height: CGFloat
        if let image = displayView.image {
            height = image.size.height * bounds.width / image.size.width
        } else {
            height = bounds.height
        }
        let size = CGSize(width: bounds.width, height: height).nanToZero()
        displayView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        
        centerContents()
        
        CATransaction.commit()
    }
    
    private func centerContents() {
        var top: CGFloat = 0, left: CGFloat = 0
        if scrollView.contentSize.height < scrollView.bounds.height {
            top = (scrollView.bounds.height - scrollView.contentSize.height) * 0.5
        }
        if scrollView.contentSize.width < scrollView.bounds.width {
            left = (scrollView.bounds.width - scrollView.contentSize.width) * 0.5
        }
        scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
    }
    
    func onDoubleTap(sender: UITapGestureRecognizer) {
        if isContentZoomed {
            isContentZoomed.toggle()
        } else {
            let scale = scrollView.maximumZoomScale
            let width = bounds.width / scale
            let height = bounds.height / scale
            let touchPoint = sender.location(in: displayView)
            let rect = CGRect(x: touchPoint.x - width * 0.5, y: touchPoint.y - height * 0.5, width: width, height: height).nanToZero()
            scrollView.zoom(to: rect, animated: true)
        }
    }
    
    open var isContentZoomed: Bool {
        get {
            return scrollView.zoomScale != 1
        }
        set {
            scrollView.setZoomScale(1, animated: true)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SlidingPhotoViewCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return displayView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContents()
    }
}
