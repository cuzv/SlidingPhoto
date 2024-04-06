import UIKit

final class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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
      let to = transitionContext.viewController(forKey: .to),
      let toView = to.view
    else {
      return transitionContext.completeTransition(false)
    }

    from.beginAppearanceTransition(false, animated: true)
    to.beginAppearanceTransition(true, animated: true)

    let container = transitionContext.containerView
    toView.frame = container.bounds
    container.addSubview(toView)
    toView.layoutIfNeeded()

    let otherViews = vc.otherViews
    let slidingPhotoView = vc.slidingPhotoView
    let currentPage = slidingPhotoView.currentIndex
    let cell = slidingPhotoView.acquireCell(for: currentPage)
    if !cell.prepared {
      cell.prepared = true
    }
    let displayView = cell.displayView

    let thumbnail = slidingPhotoView.dataSource?.slidingPhotoView?(slidingPhotoView, thumbnailForTransition: cell)
    let isContentsClippedToTop = (thumbnail as UIView?)?.sp.isContentsClippedToTop == true

    var transitionView: UIView?
    var useThumbnailData = false
    var springAdditionRatio: CGFloat = 0
    if let thumbnail {
      // Ensure cell contents loaded
      if displayView.image == nil {
        displayView.image = thumbnail.image
        useThumbnailData = true
      }

      let view = UIView()

      let fromRect = thumbnail.convert(thumbnail.bounds, to: toView).nanToZero()
      if isContentsClippedToTop {
        // Always display top content
        view.layer.anchorPoint = CGPoint(x: 0.5, y: 0)

        var destRect = displayView.convert(displayView.bounds, to: toView).nanToZero()
        let scale = (thumbnail.bounds.width / destRect.width).nanToZero()
        destRect.size.height = (thumbnail.bounds.height / scale).nanToZero()
        // y = minY, cuz anchorPoint = (0.5, 0)
        destRect.origin = CGPoint(x: fromRect.midX - destRect.width / 2.0, y: fromRect.minY)
        view.frame = destRect
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
      } else {
        view.frame = fromRect
      }

      view.layer.masksToBounds = true
      view.layer.contentsRect = thumbnail.layer.contentsRect
      view.layer.contents = thumbnail.image?.cgImage

      toView.insertSubview(view, belowSubview: vc.slidingPhotoView)
      transitionView = view
      thumbnail.alpha = 0

      springAdditionRatio = abs(container.convert(thumbnail.center, from: thumbnail).y - container.center.y) / container.center.y
    } else {
      displayView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    }

    displayView.alpha = 0
    otherViews.forEach { $0.alpha = 0 }
    UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.85 + 0.1 * springAdditionRatio, initialSpringVelocity: 0, options: [], animations: {
      otherViews.forEach { $0.alpha = 1 }

      if thumbnail != nil {
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
    }, completion: { [vc] _ in
      // Reload transition cell
      if useThumbnailData {
        slidingPhotoView.dataSource?.slidingPhotoView(slidingPhotoView, prepareForDisplay: cell)
      }
      displayView.alpha = 1
      thumbnail?.alpha = 1
      transitionView?.removeFromSuperview()
      vc?.onPresentCompletion()
      from.endAppearanceTransition()
      to.endAppearanceTransition()
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    })
  }
}
