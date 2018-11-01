//
//  SlidingPhotoViewController.swift
//  SlidingPhoto
//
//  Created by Shaw on 9/15/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit

open class SlidingPhotoViewController: UIViewController {
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    open var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public let slidingPhotoView: SlidingPhotoView = {
        let view = SlidingPhotoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var otherViews: [UIView] {
        return view.subviews.filter({ $0 != slidingPhotoView })
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        view.addSubview(dimmingView)
        dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        dimmingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        view.addSubview(slidingPhotoView)
        slidingPhotoView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        slidingPhotoView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        slidingPhotoView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        slidingPhotoView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        slidingPhotoView.delegate = self
        slidingPhotoView.dataSource = self
        slidingPhotoView.panGestureRecognizer.addTarget(self, action: #selector(onPan(sender:)))
    }
    
    open func willTriggerInteractiveDismiss() {
    }
}

extension SlidingPhotoViewController: SlidingPhotoViewDataSource, SlidingPhotoViewDelegate {
    open func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int { return 0 }
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, prepareForDisplay cell: SlidingPhotoViewCell) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, thumbnailForTransition cell: SlidingPhotoViewCell) -> SlidingPhotoDisplayView? { return nil }
    
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdateFocus cell: SlidingPhotoViewCell) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didEndDisplaying cell: SlidingPhotoViewCell) {}

    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTapped cell: SlidingPhotoViewCell, at location: CGPoint) {}
    open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didLongPressed cell: SlidingPhotoViewCell, at location: CGPoint) {}
}

extension SlidingPhotoViewController {
    @objc private func onPan(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            otherViews.forEach({ $0.sp.alpha = $0.alpha })
        case .changed:
            let translation = sender.translation(in: sender.view).y
            let ratio = abs(translation / view.bounds.size.height)
            slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translation)
            otherViews.forEach({ let alpha = $0.sp.alpha - ratio; $0.alpha = alpha < 0 ? 0 : alpha })
        case .ended:
            let velocity = sender.velocity(in: sender.view).y
            let translation = sender.translation(in: sender.view).y
            let isMoveUp = velocity < -1000 && translation < 0
            let isMoveDown = velocity > 1000 && translation > 0
            if isMoveUp || isMoveDown {
                willTriggerInteractiveDismiss()
                
                let height = slidingPhotoView.bounds.size.height
                let duration = TimeInterval(0.25 * (height - abs(translation)) / height)
                let translationY = height * (isMoveUp ? -1.0 : 1.0)
                UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    self.slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translationY)
                    self.otherViews.forEach({ $0.alpha = 0 })
                }, completion: { _ in
                    self.presentingViewController?.dismiss(animated: false, completion: nil)
                })
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
                    self.slidingPhotoView.transform = .identity
                    self.otherViews.forEach({ $0.alpha = $0.sp.alpha })
                }, completion: nil)
            }
        default:
            slidingPhotoView.transform = .identity
            otherViews.forEach({ $0.alpha = $0.sp.alpha })
        }
    }
}

extension SlidingPhotoViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentationAnimator(vc: self)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissionAnimator(vc: self)
    }
}

private final class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var vc: SlidingPhotoViewController!
    init(vc: SlidingPhotoViewController) {
        self.vc = vc
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.viewController(forKey: .to)?.view else {
            return transitionContext.completeTransition(false)
        }
        
        let container = transitionContext.containerView
        toView.frame = container.bounds
        container.addSubview(toView)
        toView.layoutIfNeeded()
        
        let otherViews = vc.otherViews
        let slidingPhotoView = vc.slidingPhotoView
        let currentPage = slidingPhotoView.currentPage
        let cell = slidingPhotoView.acquireCell(for: currentPage)
        let displayView = cell.displayView
        
        let thumbnail = slidingPhotoView.dataSource?.slidingPhotoView?(slidingPhotoView, thumbnailForTransition: cell)
        let isContentsClippedToTop = (thumbnail as UIView?)?.sp.isContentsClippedToTop == true

        var transitionView: UIView?
        var useThumbnailData = false
        if let thumbnail = thumbnail {
            // Ensure cell contents loaded
            if nil == displayView.image {
                displayView.image = thumbnail.image
                useThumbnailData = true
            }
            
            let view = UIView()
            
            let fromRect = thumbnail.convert(thumbnail.bounds, to: toView)
            if isContentsClippedToTop {
                // Always display top content
                view.layer.anchorPoint = CGPoint(x: 0.5, y: 0)

                var destRect = displayView.convert(displayView.bounds, to: toView)
                let scale = thumbnail.bounds.width / destRect.width
                destRect.size.height = thumbnail.bounds.height / scale
                // y = minY, cuz anchorPoint = (0.5, 0)
                destRect.origin = CGPoint(x: fromRect.midX - destRect.width / 2.0, y: fromRect.minY)
                view.frame = destRect
                view.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else {
                view.frame = fromRect
            }

            view.sp.image = thumbnail.image
            
            toView.insertSubview(view, aboveSubview: vc.slidingPhotoView)
            transitionView = view
        } else {
            displayView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }

        displayView.alpha = 0
        otherViews.forEach({ $0.alpha = 0 })
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            otherViews.forEach({ $0.alpha = 1 })

            if nil != thumbnail {
                if isContentsClippedToTop {
                    transitionView?.transform = .identity
                }
                transitionView?.frame = displayView.convert(displayView.bounds, to: toView)
                transitionView?.contentMode = displayView.contentMode // .scaleAspectFill
                transitionView?.layer.contentsRect = displayView.layer.contentsRect // {0, 0, 1, 1}
            } else {
                displayView.transform = .identity
                displayView.alpha = 1
            }
        }, completion: { _ in
            // Reload transition cell
            if useThumbnailData {
                slidingPhotoView.dataSource?.slidingPhotoView(slidingPhotoView, prepareForDisplay: cell)
            }
            displayView.alpha = 1
            transitionView?.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

private final class DismissionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var vc: SlidingPhotoViewController!
    init(vc: SlidingPhotoViewController) {
        self.vc = vc
        super.init()
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.viewController(forKey: .from)?.view else {
            return transitionContext.completeTransition(false)
        }
        let container = transitionContext.containerView
        container.addSubview(fromView)
        
        let otherViews = vc.otherViews
        let slidingPhotoView = vc.slidingPhotoView
        let currentPage = slidingPhotoView.currentPage
        let cell = slidingPhotoView.acquireCell(for: currentPage)
        let displayView = cell.displayView
        
        let thumbnail = slidingPhotoView.dataSource?.slidingPhotoView?(slidingPhotoView, thumbnailForTransition: cell)
        let isContentsClippedToTop = (thumbnail as UIView?)?.sp.isContentsClippedToTop == true
        
        var transitionView: UIView?
        if nil != thumbnail {
            let view = UIView()
            view.clipsToBounds = true
            if isContentsClippedToTop {
                view.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
                cell.scrollView.contentOffset = .zero
            }
            view.frame = displayView.convert(displayView.bounds, to: fromView)
            view.sp.image = displayView.image
            fromView.insertSubview(view, aboveSubview: vc.slidingPhotoView)
            transitionView = view
            
            displayView.alpha = 0
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 10, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            otherViews.forEach({ $0.alpha = 0 })

            if let thumbnail = thumbnail {
                let destRect = thumbnail.convert(thumbnail.bounds, to: fromView)
                if isContentsClippedToTop {
                    var rect = displayView.convert(displayView.bounds, to: fromView)
                    var height = thumbnail.bounds.height / thumbnail.bounds.width * displayView.bounds.width
                    if height.isNaN {
                        height = displayView.bounds.width
                    }
                    rect.size.height = height
                    // y = minY, cuz anchorPoint = (0.5, 0)
                    rect.origin = CGPoint(x: destRect.midX - rect.width / 2.0, y: destRect.minY)
                    transitionView?.frame = rect

                    let scale = thumbnail.bounds.width / displayView.bounds.width
                    transitionView?.transform = CGAffineTransform(scaleX: scale, y: scale)
                } else {
                    transitionView?.frame = destRect
                    transitionView?.contentMode = thumbnail.contentMode
                }
                transitionView?.layer.contentsRect = thumbnail.layer.contentsRect
            } else {
                slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: slidingPhotoView.bounds.height)
            }
        }, completion: { _ in
            displayView.alpha = 1
            otherViews.forEach({ $0.alpha = 1 })
            transitionView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            transitionView?.transform = .identity
            transitionView?.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
