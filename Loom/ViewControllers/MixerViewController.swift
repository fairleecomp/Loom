import UIKit

class MixerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Mixer"
        setupMixerUI()
    }
    
    func setupMixerUI() {
        // Create a vertical stack view to hold track labels (and later, controls).
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Constrain stack view to the safe area.
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Add 8 placeholder labels for each track.
        for i in 1...8 {
            let label = UILabel()
            label.text = "Track \(i)"
            label.font = UIFont.systemFont(ofSize: 18)
            stackView.addArrangedSubview(label)
        }
    }
}
