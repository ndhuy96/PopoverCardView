//
//  BottomSheetController.swift
//  PopoverCardView
//
//  Created by mac on 7/6/19.
//  Copyright © 2019 sun. All rights reserved.
//

import UIKit

open class BottomSheetController: UIViewController {
    
    // initial positon of the bottom sheet
    open var initialPosition: SheetPosition {
        return .middle
    }
    
    // current position of the bottom sheet
    open var nextPosition: SheetPosition!
    
    // 1 : full height, 0 : minimum height default is 1
    open var topYPercentage: CGFloat {
        return 1.0
    }
    
    // 1 : full height, 0 : minimum height default is 0.5
    open var middleYPercentage: CGFloat {
        return 0.5
    }
    
    // 1 : full height, 0 : minimum height default is 0.1
    open var bottomYPercentage: CGFloat {
        return 0.1
    }
    
    // using superview bottom inset is recommended default is 0
    open var bottomInset: CGFloat {
        return 0
    }
    
    // using safe area top inset is recommended default is 80
    open var topInset: CGFloat {
        return 80.0
    }
    
    // bottom sheet full height
    var fullHeight: CGFloat {
        return (parent?.view.frame.height ?? UIScreen.main.bounds.height) - topInset - bottomInset
    }
    
    // y coordinate of bottom sheet in top position
    var topY: CGFloat {
        return (1 - topYPercentage) * fullHeight + topInset - bottomInset
    }
    
    // y coordinate of bottom sheet in middle position
    var middleY: CGFloat {
        return (1 - middleYPercentage) * fullHeight + topInset - bottomInset
    }
    
    // y coordinate of bottom sheet in bottom position
    var bottomY: CGFloat {
        return (1 - bottomYPercentage) * fullHeight + topInset - bottomInset
    }
    
    // view area using pan gesture
    var panView: UIView! {
        return view
    }
    
    // View contain bottom sheet view controller (Parental subview)
    fileprivate var containerView = UIView()
    
    fileprivate var lastOffset: CGPoint = .zero
    fileprivate var startLocation: CGPoint = .zero
    fileprivate var freezeContentOffset = false
    
    open var scrollView: UIScrollView? {
        return autoDetectedScrollView
    }
    
    fileprivate var autoDetectedScrollView: UIScrollView?
    fileprivate var didLayoutOnce = false
    fileprivate var topConstraint: NSLayoutConstraint?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
        addObserver()
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        panView.frame = containerView.bounds
        
        if !didLayoutOnce {
            didLayoutOnce = true
            snapTo(position: self.initialPosition)
        }
    }
    
    fileprivate func addObserver() {
        scrollView?.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new, .old], context: nil)
    }
    
    fileprivate func findScrollView(from view: UIView) -> UIView? {
        return view.ub_firstSubView(ofType: UIScrollView.self)
    }
    
    fileprivate func setupGestures() {
        if autoDetectedScrollView == nil {
            autoDetectedScrollView = findScrollView(from: self.view) as? UIScrollView
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.view.addGestureRecognizer(pan)
        self.scrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UIScrollView.contentOffset) {
            // scroll up -> contentOffsetY is negative value
            if let scroll = scrollView, scroll.contentOffset.y < 0 {
                scrollView?.setContentOffset(.zero, animated: false)
            }
        }
    }
    
    @objc
    fileprivate func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            break
        case .changed:
            dragView(recognizer)
        default:
            self.nextPosition = nextLevel(recognizer: recognizer)
            snapTo(position: nextPosition)
        }
    }
    
    @objc
    fileprivate func handleScrollPan(_ recognizer: UIPanGestureRecognizer) {
        let vel = recognizer.velocity(in: self.panView)
        
        // scroll down
        if scrollView!.contentOffset.y > 0 && vel.y >= 0 {
            lastOffset = scrollView!.contentOffset
            startLocation = recognizer.translation(in: self.scrollView!)
            return
        }
        
        switch recognizer.state {
        case .began:
            freezeContentOffset = false
            lastOffset = scrollView!.contentOffset
            startLocation = recognizer.translation(in: self.scrollView!)
        case .changed:
            let dy = recognizer.translation(in: self.scrollView!).y - startLocation.y
            let f = getFrame(for: dy)
            topConstraint?.constant = f.minY

            startLocation = recognizer.translation(in: self.scrollView!)
            // scroll up
            if containerView.frame.minY > topY && vel.y < 0 {
                freezeContentOffset = true
                // stop subview's scrollview moving when bottom sheet scrolling up
                scrollView!.setContentOffset(lastOffset, animated: false)
            } else {
                lastOffset = scrollView!.contentOffset
            }
        default:
            self.nextPosition = nextLevel(recognizer: recognizer)
            snapTo(position: self.nextPosition)
        }
    }
    
    fileprivate func dragView(_ recognizer: UIPanGestureRecognizer) {
        let dy = recognizer.translation(in: self.panView).y
        topConstraint?.constant = getFrame(for: dy).minY
        recognizer.setTranslation(.zero, in: self.panView)
    }
    
    fileprivate func getFrame(for dy: CGFloat) -> CGRect {
        let f = containerView.frame
        let minY = min(max(topY, f.minY + dy), bottomY)
        let h = f.maxY - minY
        return CGRect(x: f.minX, y: minY, width: f.width, height: h)
    }
    
    fileprivate func snapTo(position: SheetPosition) {
        let f = self.containerView.frame == .zero ? self.view.frame : self.containerView.frame
        var minY: CGFloat
        
        switch position {
        case .top:
            minY = topY
        case .middle:
            minY = middleY
        case .bottom:
            minY = bottomY
        }
        
        if freezeContentOffset && scrollView!.panGestureRecognizer.state == .ended {
            scrollView!.setContentOffset(lastOffset, animated: false)
        }
        
        let h = f.maxY - minY
        let rect = CGRect(x: f.minX, y: minY, width: f.width, height: h)
        self.topConstraint?.constant = rect.minY
        
        animate(animations: {
            self.parent?.view.layoutIfNeeded()
        })
    }
    
    // Bottom sheet animation
    open func animate(animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut], animations: animations, completion: nil)
    }
    
    fileprivate func nextLevel(recognizer: UIPanGestureRecognizer) -> SheetPosition {
        let y = self.containerView.frame.minY
        // scroll up -> velY is negative value
        // scroll down -> velY is positive value
        let velY = recognizer.velocity(in: self.view).y
        if velY < -150 {
            if velY < -1000 {
                return .top
            }
            return y > middleY ? .middle : .top
        } else if velY > 150 {
            if velY > 1000 {
                return .bottom
            }
            return y < middleY ? .middle : .bottom
        } else {
            if y > middleY {
                return (y - middleY) < (bottomY - y) ? .middle : .bottom
            } else {
                return (y - topY) < (middleY - y) ? .top : .middle
            }
        }
    }
}

extension BottomSheetController: Positioning {
    public func changePosition(to position: SheetPosition) {
        snapTo(position: position)
    }
}

extension BottomSheetController: Pannable {
    public func attach(to parent: UIViewController) {
        parent.ub_add(self, in: containerView) { (view) in
            view.edges([.left, .right, .top, .bottom], to: parent.view, offset: .zero)
        }
        
        topConstraint = parent.view.constraints.first { (c) -> Bool in
            c.firstItem as? UIView == self.containerView && c.firstAttribute == .top
        }
        
        let bottomConstraint = parent.view.constraints.first { (c) -> Bool in
            c.firstItem as? UIView == self.containerView && c.firstAttribute == .bottom
        }
        
        bottomConstraint?.constant = -bottomInset
    }
    
    public func detach() {
        self.ub_remove()
        self.containerView.removeFromSuperview()
    }
}

