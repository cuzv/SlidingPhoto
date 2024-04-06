import UIKit

final class DismissionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  private weak var vc: SlidingPhotoViewController!

  init(vc: SlidingPhotoViewController) {
    self.vc = vc
    super.init()
  }

  public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    0.25
  }

  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard
      let from = transitionContext.viewController(forKey: .from),
      let fromView = from.view,
      let to = transitionContext.viewController(forKey: .to)
    else {
      return transitionContext.completeTransition(false)
    }
    from.beginAppearanceTransition(false, animated: true)
    to.beginAppearanceTransition(true, animated: true)

    let container = transitionContext.containerView
    container.addSubview(fromView)

    let otherViews = vc.otherViews
    let slidingPhotoView = vc.slidingPhotoView
    let currentPage = slidingPhotoView.currentIndex
    let cell = slidingPhotoView.acquireCell(for: currentPage)
    let displayView = cell.displayView

    let thumbnail = slidingPhotoView.dataSource?.slidingPhotoView?(slidingPhotoView, thumbnailForTransition: cell)
    let isContentsClippedToTop = (thumbnail as UIView?)?.sp.isContentsClippedToTop == true

    var transitionView: UIView?
    if thumbnail != nil {
      let view = UIView()
      if isContentsClippedToTop {
        view.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        cell.scrollView.contentOffset = .zero
      }
      view.frame = displayView.convert(displayView.bounds, to: fromView)
      view.layer.masksToBounds = true
      view.layer.contentsRect = displayView.layer.contentsRect
      view.layer.contents = displayView.image?.cgImage

      fromView.insertSubview(view, belowSubview: vc.slidingPhotoView)
      transitionView = view
      displayView.alpha = 0
    }

    UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: [], animations: {
      otherViews.forEach { $0.alpha = 0 }

      if let thumbnail {
        let destRect = thumbnail.convert(thumbnail.bounds, to: fromView).nanToZero()
        if isContentsClippedToTop {
          var rect = displayView.convert(displayView.bounds, to: fromView).nanToZero()
          var height = thumbnail.bounds.height / thumbnail.bounds.width * displayView.bounds.width
          if height.isNaN {
            height = displayView.bounds.width
          }
          rect.size.height = height
          // y = minY, cuz anchorPoint = (0.5, 0)
          rect.origin = CGPoint(x: destRect.midX - rect.width / 2.0, y: destRect.minY)
          transitionView?.frame = rect

          let scale = thumbnail.bounds.width / displayView.bounds.width.nanToZero()
          transitionView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        } else {
          transitionView?.frame = destRect
          transitionView?.contentMode = thumbnail.contentMode
        }
        transitionView?.layer.contentsRect = thumbnail.layer.contentsRect
      } else {
        slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: slidingPhotoView.bounds.height)
      }
    }, completion: { [vc] _ in
      displayView.alpha = 1
      otherViews.forEach { $0.alpha = 1 }
      transitionView?.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
      transitionView?.transform = .identity
      transitionView?.removeFromSuperview()
      vc?.onDimissCompletion()
      from.endAppearanceTransition()
      to.endAppearanceTransition()
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    })
  }
}
