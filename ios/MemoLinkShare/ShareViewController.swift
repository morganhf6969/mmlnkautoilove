import UIKit
import Social

class ShareViewController: UIViewController {

    private let urlTypeIdentifier = "public.url"
    private let textTypeIdentifier = "public.plain-text"
    private var didComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedContent()
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 20
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let icon = UILabel()
        icon.text = "🔗"
        icon.font = .systemFont(ofSize: 44)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "MemoLink"
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = .label
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "Salvataggio link in corso…"
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .secondaryLabel
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(icon)
        container.addSubview(title)
        container.addSubview(subtitle)
        container.addSubview(spinner)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 260),
            container.heightAnchor.constraint(equalToConstant: 140),

            icon.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 8),
            title.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            subtitle.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            spinner.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 10),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])
    }

    // MARK: - Sharing

    private func handleSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(urlTypeIdentifier) {
                    provider.loadItem(forTypeIdentifier: urlTypeIdentifier, options: nil) { [weak self] (data, _) in
                        DispatchQueue.main.async {
                            let urlString: String?
                            if let url = data as? URL { urlString = url.absoluteString }
                            else if let s = data as? String { urlString = s }
                            else if let d = data as? Data { urlString = String(data: d, encoding: .utf8) }
                            else { urlString = nil }
                            self?.saveAndOpen(urlString: urlString)
                        }
                    }
                    return
                }
                if provider.hasItemConformingToTypeIdentifier(textTypeIdentifier) {
                    provider.loadItem(forTypeIdentifier: textTypeIdentifier, options: nil) { [weak self] (data, _) in
                        DispatchQueue.main.async {
                            self?.saveAndOpen(urlString: data as? String)
                        }
                    }
                    return
                }
            }
        }
        completeRequest()
    }

    private func saveAndOpen(urlString: String?) {
        guard let urlString, !urlString.isEmpty,
              let defaults = UserDefaults(suiteName: "group.com.memolink.sharing") else {
            completeRequest()
            return
        }

        defaults.set(urlString, forKey: "shared_url")
        defaults.synchronize()

        // Tenta apertura automatica dell'app (funziona su iOS < 26)
        if let appURL = URL(string: "memolink://share") {
            extensionContext?.open(appURL, completionHandler: nil)
        }

        // Completa dopo un breve delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.completeRequest()
        }
    }

    private func completeRequest() {
        guard !didComplete else { return }
        didComplete = true
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
