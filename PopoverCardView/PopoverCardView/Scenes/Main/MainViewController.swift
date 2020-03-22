//
//  MainViewController.swift
//  PopoverCardView
//
//  Created by mac on 7/5/19.
//  Copyright © 2019 sun. All rights reserved.
//

import UIKit

final class MainViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    private var cardViewController: CardViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        cardViewController.attach(to: self)
        hideCardViewWhenTappedAround()
    }
    
    private func hideCardViewWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissCardView(_:)))
        tap.cancelsTouchesInView = true
        self.imageView.addGestureRecognizer(tap)
        self.imageView.isUserInteractionEnabled = true
    }

    @objc
    private func dismissCardView(_ recognizer: UITapGestureRecognizer) {
        cardViewController.changePosition(to: .bottom)
    }
}
