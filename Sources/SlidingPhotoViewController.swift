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

  public required init?(coder aDecoder: NSCoder) {
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
    view.subviews.filter { $0 != slidingPhotoView }
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

  open func willDismissByPanGesture() {}
  open func didDismissByPanGesture() {}
  open func onPresentCompletion() {}
  open func onDimissCompletion() {}
}

// MARK: - SlidingPhotoViewDataSource, SlidingPhotoViewDelegate

extension SlidingPhotoViewController: SlidingPhotoViewDataSource, SlidingPhotoViewDelegate {
  open func numberOfItems(in slidingPhotoView: SlidingPhotoView) -> Int { 0 }
  open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, prepareForDisplay cell: SlidingPhotoViewCell) {}
  open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, thumbnailForTransition cell: SlidingPhotoViewCell) -> SlidingPhotoDisplayView? { nil }

  open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didUpdateFocus cell: SlidingPhotoViewCell) {}
  open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didEndDisplaying cell: SlidingPhotoViewCell) {}

  open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didSingleTapped cell: SlidingPhotoViewCell, at location: CGPoint) {}
  open func slidingPhotoView(_ slidingPhotoView: SlidingPhotoView, didLongPressed cell: SlidingPhotoViewCell, at location: CGPoint) {}
}

// MARK: - UIPanGestureRecognizer

extension SlidingPhotoViewController {
  @objc private func onPan(sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      otherViews.forEach { $0.sp.alpha = $0.alpha }
    case .changed:
      let translation = sender.translation(in: sender.view).y.nanToZero()
      let ratio = abs(translation / view.bounds.size.height).nanToZero()
      slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translation)
      otherViews.forEach { let alpha = $0.sp.alpha - ratio; $0.alpha = alpha < 0 ? 0 : alpha }
    case .ended:
      let velocity = sender.velocity(in: sender.view).y
      let translation = sender.translation(in: sender.view).y
      let isMoveUp = velocity < -1000 && translation < 0
      let isMoveDown = velocity > 1000 && translation > 0
      if isMoveUp || isMoveDown {
        willDismissByPanGesture()

        let height = slidingPhotoView.bounds.size.height.nanToZero()
        let duration = TimeInterval(0.25 * (height - abs(translation)) / height).nanToZero()
        let translationY = height * (isMoveUp ? -1.0 : 1.0)
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
          self.slidingPhotoView.transform = CGAffineTransform(translationX: 0, y: translationY)
          self.otherViews.forEach { $0.alpha = 0 }
        }, completion: { _ in
          let vc = self.presentingViewController
          vc?.beginAppearanceTransition(true, animated: false)
          vc?.dismiss(animated: false) {
            vc?.endAppearanceTransition()
            self.didDismissByPanGesture()
          }
        })
      } else {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
          self.slidingPhotoView.transform = .identity
          self.otherViews.forEach { $0.alpha = $0.sp.alpha }
        }, completion: nil)
      }
    default:
      slidingPhotoView.transform = .identity
      otherViews.forEach { $0.alpha = $0.sp.alpha }
    }
  }
}

// MARK: - UIViewControllerTransitioningDelegate

extension SlidingPhotoViewController: UIViewControllerTransitioningDelegate {
  public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    PresentationAnimator(vc: self)
  }

  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    DismissionAnimator(vc: self)
  }
}
