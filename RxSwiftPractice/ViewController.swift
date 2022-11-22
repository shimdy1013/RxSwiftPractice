//
//  ViewController.swift
//  RxSwiftPractice
//

import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

class ViewController: UIViewController {
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var editView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
        }
    }

    private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
        guard let v = v else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak v] in
            v?.isHidden = !s
        }, completion: { [weak self] _ in
            self?.view.layoutIfNeeded()
        })
    }

    // MARK: SYNC

    func downloadJson(_ url: String) -> Observable<String?> {

        // 비동기로 생기는 데이터를 observable로 감싸서 return
        return Observable.create() { emitter in
            let url = URL(string: MEMBER_LIST_URL)!

            // 이 작업은 URLSession이 돌고 있는 스레드에서 발생하게 된다.
            let task = URLSession.shared.dataTask(with: url) { data, response, err in
                // error 발생 -> onError
                guard err == nil else {
                    emitter.onError(err!)
                    return
                }
                
                // data 부르기
                if let data = data, let json = String(data: data, encoding: .utf8) {
                    emitter.onNext(json)
                }
                
                // data가 불러와지면 불러와진 대로, 아니면 아닌대로 onCompleted
                emitter.onCompleted()
            }
            
            task.resume()
            
            // dispose가 불렸을 때 task를 cancel
            return Disposables.create() {
                task.cancel()
            }
        }
    }

    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBAction func onLoad() {
        editView.text = ""
        setVisibleWithAnimation(self.activityIndicator, true)
        
        // 2. Observable로 오는 데이터를 받아서 처리하는 방법
        // 변수로 처리할 필요가 없다면, chaining으로 처리하자.
        let observable = downloadJson(MEMBER_LIST_URL)
        
        
        // closure를 이용해서 데이터를 처리할 수 있다.
        // observable 이 종료되면 클로저가 사라지기 때문에 순환 참조도 사라짐.
        let disposable = observable.subscribe { event in
            switch event {
            case .next(let json):
                // subscribe에서 도는건 URLSession이 도는 스레드니까 UI Logic 을 main thread 로 옮김.
                DispatchQueue.main.async {
                    self.editView.text = json
                    self.setVisibleWithAnimation(self.activityIndicator, false)
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.editView.text = error.localizedDescription
                    self.setVisibleWithAnimation(self.activityIndicator, false)
                }
            case .completed:
                break
            }
        }
        
        // disposable.dispose()

    }
}
