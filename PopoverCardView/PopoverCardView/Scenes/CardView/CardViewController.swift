//
//  CardViewController.swift
//  PopoverCardView
//
//  Created by mac on 7/6/19.
//  Copyright © 2019 sun. All rights reserved.
//

import UIKit

final class CardViewController: BottomSheetController {
        //MARK: BottomSheetController configurations
    //    override var initialPosition: SheetPosition {
    //        return .middle
    //    }
            
    //    override var topYPercentage: CGFloat
        
    //    override var bottomYPercentage: CGFloat
        
    //    override var middleYPercentage: CGFloat
        
    //    override var bottomInset: CGFloat
        
    //    override var topInset: CGFloat
        
    //    Don't override if not necessary as it is auto-detected
    //    override var scrollView: UIScrollView?{
    //        return put_your_tableView, collectionView, etc.
    //    }
        
    //    // Override this to apply custom animations
    //    override func animate(animations: @escaping () -> Void) {
    //        UIView.animate(withDuration: 0.3, animations: animations)
    //    }
        
    //    To change sheet position manually
    //    call ´changePosition(to: .top)´ anywhere in the code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.roundCorners(corners: [.topLeft, .topRight], radius: 12)
    }
}
