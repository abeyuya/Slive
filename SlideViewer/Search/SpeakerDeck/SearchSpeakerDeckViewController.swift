//
//  SearchSpeakerDeckViewController.swift
//  SlideViewer
//
//  Created by abeyuya on 2017/12/31.
//  Copyright © 2017年 abeyuya. All rights reserved.
//

import UIKit
import WebKit
import XLPagerTabStrip
import RxSwift
import RxWebKit

final class SearchSpeakerDeckViewController: UIViewController, IndicatorInfoProvider {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressView: UIProgressView!
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.rx.estimatedProgress
            .subscribe(onNext: { [weak self] progress in
                self?.progressView.isHidden = false
                self?.progressView.setProgress(Float(progress), animated: true)
                
                if progress == 1 {
                    self?.progressView.isHidden = true
                    self?.progressView.setProgress(0.0, animated: false)
                }
            })
            .disposed(by: disposeBag)

        webView.rx.url
            .subscribe(onNext: { url in
                guard let url = url else { return }
                print("url: \(url)")
            })
            .disposed(by: disposeBag)

        let startURL = URL(string: "https://speakerdeck.com/")!
        let request = URLRequest(url: startURL)
        webView.load(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "My Child title")
    }
}
