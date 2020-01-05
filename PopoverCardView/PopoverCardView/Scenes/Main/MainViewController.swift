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
        endCardHeight = self.view.frame.height * 0.8
        startCardHeight = self.view.frame.height * 0.3
        
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
        switch recognizer.state {
        case .began:
            // Start animation if pan begins
            startInteractiveTransition(state: nextState, duration: 0.5)
        case .changed:
            // Update the translation according to the percentage completed
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / endCardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            // End animation when pan ends
            continueInteractiveTransition()
        default:
            break
        }
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
                animateTransitionIfNeeded(state: .collapsed, duration: 0.5)
            }
        default:
            break
        }
    }
    
    // Animate transistion function
    private func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        // Check if frame animator is empty
        if runningAnimations.isEmpty {
            // Create a UIViewPropertyAnimator depending on the state of the popover view
            // The damping ratio to apply to the initial acceleration and oscillation.
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    // If expanding set popover y to the ending height and blur background
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.endCardHeight
                case .collapsed:
                    // If collapsed set popover y to the starting height and remove background blur
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.startCardHeight
                }
            }
            
            // Complete animation frame
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
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
    private func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        // If animation is empty start new animation
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Pause animation and update the progress to the fraction complete percentage
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    // Funtion to update transition when view is dragged
    private func updateInteractiveTransition(fractionCompleted: CGFloat) {
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Update the fraction complete value to the current progress
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    // Function to continue an interactive transisiton
    private func continueInteractiveTransition() {
        // For each animation in runningAnimations
        for animator in runningAnimations {
            // Continue the animation forwards or backwards
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
