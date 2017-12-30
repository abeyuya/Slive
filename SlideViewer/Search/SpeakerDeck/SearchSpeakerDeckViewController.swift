//
//  SearchSpeakerDeckViewController.swift
//  SlideViewer
//
//  Created by abeyuya on 2017/12/31.
//  Copyright © 2017年 abeyuya. All rights reserved.
//

import UIKit
import XLPagerTabStrip

final class SearchSpeakerDeckViewController: UIViewController, IndicatorInfoProvider {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "My Child title")
    }
}
