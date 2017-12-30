//
//  SearchViewController.swift
//  SlideViewer
//
//  Created by abeyuya on 2017/12/31.
//  Copyright © 2017年 abeyuya. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Rswift

final class SearchViewController: ButtonBarPagerTabStripViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let v = R.storyboard.searchSpeakerDeck.instantiateInitialViewController()!
        return [v]
    }
}
