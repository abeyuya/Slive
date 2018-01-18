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
import Kanna
import SlideViewer

final class SearchSpeakerDeckViewController: UIViewController, IndicatorInfoProvider {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var viewButton: UIButton!
    
    private struct ScrapeResult {
        var title: String? = nil
        var author: String? = nil
        var authorImagePath: String? = nil
        var mainImageURLs: [URL] = []
        var thumbImageURLs: [URL] = []
    }

    private let disposeBag = DisposeBag()
    private var scrapeResult: Variable<ScrapeResult> = Variable(ScrapeResult())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()

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

extension SearchSpeakerDeckViewController {
 
    private func bind() {
        
        webView.rx.estimatedProgress
            .subscribe(onNext: { [weak self] progress in
                self?.renderProgress(progress: progress)
            })
            .disposed(by: disposeBag)
        
        webView.rx.url
            .flatMap { url -> Observable<URL> in
                guard let url = url else { return Observable.empty() }
                return Observable.just(url)
            }
            .subscribe(onNext: { [weak self] url in
                self?.scrape(url: url)
            })
            .disposed(by: disposeBag)
        
        scrapeResult.asObservable()
            .subscribe(onNext: { [weak self] scrapeResult in
                guard 0 < scrapeResult.mainImageURLs.count,
                    0 < scrapeResult.thumbImageURLs.count else {
                        DispatchQueue.main.async {
                            self?.viewButton.isEnabled = false
                        }
                        return
                }
                
                self?.viewButton.isEnabled = true
            })
            .disposed(by: disposeBag)

        viewButton.rx.tap
            .subscribe { [weak self] _ in
                guard let main = self?.scrapeResult.value.mainImageURLs,
                    let thumb = self?.scrapeResult.value.thumbImageURLs else { return }
                
                let authroImageURL: URL? = {
                    guard let path = self?.scrapeResult.value.authorImagePath else {
                        return nil
                    }
                    return URL(string: path)
                }()
                
                let v = SlideViewerController.setup(
                    mainImageURLs: main,
                    thumbImageURLs: thumb,
                    avatarImageURL: authroImageURL,
                    title: self?.scrapeResult.value.title ?? "",
                    author: self?.scrapeResult.value.author ?? "")
                
                self?.present(v, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
}

extension SearchSpeakerDeckViewController {
    
    private func renderProgress(progress: Double) {
        guard progress == 1 else {
            progressView.isHidden = false
            progressView.setProgress(Float(progress), animated: true)
            return
        }
        
        progressView.isHidden = true
        progressView.setProgress(0.0, animated: false)
    }
}

extension SearchSpeakerDeckViewController {
    
    private func scrape(url :URL) {
        let request = URLRequest(url: url)
        
        URLSession.shared.rx.data(request: request)
            .flatMap { data -> Observable<FirstScrapeResult> in
                guard let doc = try? HTML(html: data, encoding: .utf8),
                    let dataId = doc.body?.css(".speakerdeck-embed").first?["data-id"],
                    let playerURL = URL(string: "https://speakerdeck.com/player/\(dataId)") else {
                        return Observable.empty()
                }

                let details = doc.body?.css("div#talk-details").first
                let title = details?.css("h1").first?.innerHTML
                let author = details?.css("a").first?.innerHTML
                let authorImagePath = doc.body?.css(".presenter").first?.css("img").first?["src"]
                
                let result = FirstScrapeResult(
                    title: title,
                    author: author,
                    authorImagePath: authorImagePath,
                    playerURL: playerURL)
                
                return Observable.just(result)
            }
            .flatMap { firstResult -> Observable<SecondScrapeResult> in
                return self.fetchTalkJson(playerURL: firstResult.playerURL)
                    .flatMap { fetchResult -> Observable<SecondScrapeResult> in
                        let secondResult = SecondScrapeResult(
                            fetchResult: fetchResult,
                            firstResult: firstResult)
                        
                        return Observable.just(secondResult)
                    }
            }
            .subscribe(onNext: { secondResult in
                let scrapeResult = ScrapeResult(
                    title: secondResult.firstResult.title,
                    author: secondResult.firstResult.author,
                    authorImagePath: secondResult.firstResult.authorImagePath,
                    mainImageURLs: secondResult.fetchResult.mainImageURLs,
                    thumbImageURLs: secondResult.fetchResult.thumbImageURLs)
                
                self.scrapeResult.value = scrapeResult
            })
            .disposed(by: disposeBag)
    }
    
    private struct FirstScrapeResult {
        let title: String?
        let author: String?
        let authorImagePath: String?
        let playerURL: URL
    }
    
    private struct SecondScrapeResult {
        let fetchResult: FetchResult
        let firstResult: FirstScrapeResult
    }
    
    private struct FetchResult {
        let mainImageURLs: [URL]
        let thumbImageURLs: [URL]
    }

    private func fetchTalkJson(playerURL: URL) -> Observable<FetchResult> {
        
        return load(playerURL: playerURL)
            .flatMap { _webview in
                return _webview.rx.loading.flatMap { loading -> Observable<WKWebView> in
                    if loading { return Observable<WKWebView>.empty() }
                    return Observable.just(_webview)
                }
            }
            .subscribeOn(MainScheduler.instance)
            .flatMap { _webview -> Observable<Any?> in
                return Observable<Any?>.create { observer in
                    _webview.evaluateJavaScript("JSON.stringify(talk)") { res, error in
                        if let error = error { return observer.onError(error) }
                        observer.onNext(res)
                    }
                    return SingleAssignmentDisposable()
                }
            }
            .flatMap { res -> Observable<Talk> in
                let decorder = JSONDecoder()
                guard let res = res as? String,
                    let data = res.data(using: .utf8),
                    let talk = try? decorder.decode(Talk.self, from: data) else {
                        return Observable.empty()
                }
                
                return Observable.just(talk)
            }
            .flatMap { talk -> Observable<FetchResult> in
                let main: [URL] = talk.slides.map { URL(string: $0.original)! }
                let thumb: [URL] = talk.slides.map { URL(string: $0.thumb)! }
                
                let result = FetchResult(mainImageURLs: main, thumbImageURLs: thumb)
                return Observable.just(result)
            }
    }
    
    private func load(playerURL: URL) -> Observable<WKWebView> {
        return Observable<WKWebView>.create { observer in
            DispatchQueue.main.async {
                let _webview = WKWebView()
                _webview.load(URLRequest(url: playerURL))
                observer.onNext(_webview)
            }
            
            return SingleAssignmentDisposable()
        }
    }
}
