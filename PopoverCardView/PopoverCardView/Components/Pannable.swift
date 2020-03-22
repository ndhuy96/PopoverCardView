//
//  Pannable.swift
//  PopoverCardView
//
//  Created by mac on 7/6/19.
//  Copyright © 2019 sun. All rights reserved.
//

import UIKit

public protocol Pannable {
    func attach(to parent: UIViewController)
    func detach()
}
 
