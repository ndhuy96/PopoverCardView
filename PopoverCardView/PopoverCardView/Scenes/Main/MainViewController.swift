//
//  MainViewController.swift
//  PopoverCardView
//
//  Created by mac on 7/5/19.
//  Copyright © 2019 sun. All rights reserved.
//

import UIKit

// Enum for card states
enum CardState {
    case collapsed
    case expanded
}

final class MainViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    // Variable determines the next state of the card expressing that the card starts and collapsed
    private var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    // Duration Animation of cardView
    private var duration: TimeInterval!
    
    // Variable for average fraction value of cardView
    private var averageFractionValue: CGFloat!
    
    // Variable for card view controller
    private var cardViewController: CardViewController!

    // Starting and end card heights will be determined later
    private var startCardHeight: CGFloat = 0
    private var endCardHeight: CGFloat = 0

    
    // Current visible state of the card
    private var cardVisible = false
    
    // Empty property animator array
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationProgressWhenInterrupted: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
        hideCardViewWhenTappedAround()
    }
    
    private func setupCard() {
        // Setup starting and ending card height
        startCardHeight = self.view.frame.height * 0.2
        endCardHeight = self.view.frame.height * 0.8
        averageFractionValue = 0.4
        duration = 1.0
        
        // Add CardViewController xib to the bottom of the screen, clipping bounds so that the corners can be rounded
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - startCardHeight,
                                               width: self.view.bounds.width, height: endCardHeight)
        cardViewController.view.clipsToBounds = true
        
        // Add tap and pan recognizers
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan))
        cardViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // Handle pan gesture recognizer
    @objc
    private func handleCardPan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.cardViewController.handleArea)
        switch recognizer.state {
        case .began:
            // Start animation if pan begins
            startInteractiveTransition(state: nextState)
        case .changed:
            // Update the translation according to the percentage completed
            if let fractionComplete = calculateFractionComplete(translationY: translation.y) {
                updateInteractiveTransition(fractionCompleted: fractionComplete)
            }
        case .ended:
            // End animation when pan ends
            if let fractionComplete = calculateFractionComplete(translationY: translation.y) {
                if fractionComplete >= averageFractionValue {
                    self.cardVisible = !self.cardVisible
                }
                continueInteractiveTransition(fractionCompleted: fractionComplete)
            }
        default:
            break
        }
    }
    
    // Calculate fractionComplete when swipping cardview
    private func calculateFractionComplete(translationY: CGFloat) -> CGFloat? {
        guard validateCardViewDirection(translationY: translationY) else {
            return nil
        }
        
        var fractionComplete = translationY / (endCardHeight - startCardHeight)
        fractionComplete = cardVisible ? fractionComplete : -fractionComplete
        
        if fractionComplete > 1 {
            fractionComplete = 1
        } else if fractionComplete < 0 {
            fractionComplete = 0
        }
        
        return fractionComplete
    }
    
    // Validate cardview's direction
    private func validateCardViewDirection(translationY: CGFloat) -> Bool {
        if translationY < 0 && cardVisible { // avoid swipping down cardview when card is expanded
            return false
        } else if translationY > 0 && !cardVisible { // avoid swipping up cardview when card is collapsed
            return false
        }
        return true
    }
    
    private func hideCardViewWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissCardView(_:)))
        tap.cancelsTouchesInView = true
        self.imageView.addGestureRecognizer(tap)
        self.imageView.isUserInteractionEnabled = true
    }
    
    @objc
    private func dismissCardView(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        // Animate card when tap finishes
        case .ended:
            if nextState == .collapsed {
                animateTransitionIfNeeded(state: .collapsed)
            }
        default:
            break
        }
    }
    
    // Animate transistion function
    private func animateTransitionIfNeeded(state: CardState) {
        // Check if frame animator is empty
        if runningAnimations.isEmpty {
            // Create a UIViewPropertyAnimator depending on the state of the popover view
            // The damping ratio to apply to the initial acceleration and oscillation.
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.75) {
                switch state {
                case .expanded:
                    // if expanded set popover y to the ending height
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.endCardHeight
                case .collapsed:
                    // If collapsed set popover y to the starting height
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.startCardHeight
                }
            }
            
            // Execute when animation frame is completed
            frameAnimator.addCompletion { _ in
                self.runningAnimations.removeAll()
            }
            
            // Start animation
            frameAnimator.startAnimation()
            
            // Append animation to running animations
            runningAnimations.append(frameAnimator)
            
            // Create UIViewPropertyAnimator to round the popover view corners depending on the state of the popover
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    // If the view is expanded set the corner radius to 12
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    // If the view is collapsed set the corner radius to 0
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            // Start the corner radius animation
            cornerRadiusAnimator.startAnimation()
            
            // Append animation to running animations
            runningAnimations.append(cornerRadiusAnimator)
        }
    }
    
    // Function to start interactive animations when view is dragged
    private func startInteractiveTransition(state: CardState) {
        // If animation is empty start new animation
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state)
        }
        
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Pause animation and update the progress to the fraction complete percentage
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    // Function to update transition when view is dragged
    private func updateInteractiveTransition(fractionCompleted: CGFloat) {
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Update the fraction complete value to the current progress
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    // Function to continue an interactive transititon
    private func continueInteractiveTransition(fractionCompleted: CGFloat) {
        if fractionCompleted < averageFractionValue {
            self.runningAnimations.forEach {
                $0.isReversed = true
            }
        } else {
            self.runningAnimations.forEach {
                $0.isReversed = false
            }
        }
    
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Continue the animation forwards or backwards
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
