import UIKit
@preconcurrency import WebKit

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

final class WebViewViewController: UIViewController {
    @IBOutlet private var webView: WKWebView!
    
    @IBOutlet private var progressView: UIProgressView!
    
    weak var delegate: WebViewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadAuthView()
        updateProgress()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webView.addObserver(
            self,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil)
        updateProgress()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            updateProgress()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            print("unsplashAuthorizeURLString error")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            print("URLcomponents error")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        delegate?.webViewViewControllerDidCancel(WebViewViewController())
    }
}

extension WebViewViewController: WKNavigationDelegate {
    
    func code(from navigationAction: WKNavigationAction) -> String? {
        if
            let url = navigationAction.request.url,
            let urlComponents = URLComponents(string: url.absoluteString),
            urlComponents.path == "/oauth/authorize/native",
            let items = urlComponents.queryItems,
            let codeItem = items.first(where: { $0.name == "code" })
        {
            return codeItem.value
        } else {
            print("Code error")
            return nil
        }
    }
    
    
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let code = code(from: navigationAction) {
                delegate?.webViewViewController(self, didAuthenticateWithCode: code)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
}