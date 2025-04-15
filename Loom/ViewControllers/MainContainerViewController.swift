import UIKit

class MainContainerViewController: UIViewController, UIGestureRecognizerDelegate {

    // Child view controllers
    var recordingVC: RecordingViewController!
    var mixerVC: MixerViewController!
    var savedRecordingsVC: SavedRecordingsViewController!
    
    // Pan gesture recognizer
    var panGesture: UIPanGestureRecognizer!
    
    // How much of the container’s width the side panels overlay when fully revealed.
    let overlayFraction: CGFloat = 0.5

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate child view controllers from storyboard using their Storyboard IDs.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let recVC = storyboard.instantiateViewController(withIdentifier: "RecordingViewController") as? RecordingViewController,
              let mixVC = storyboard.instantiateViewController(withIdentifier: "MixerViewController") as? MixerViewController,
              let savedVC = storyboard.instantiateViewController(withIdentifier: "SavedRecordingsViewController") as? SavedRecordingsViewController
        else {
            fatalError("One or more child view controllers could not be instantiated from the storyboard. Check your storyboard IDs and custom classes.")
        }
        
        recordingVC = recVC
        mixerVC = mixVC
        savedRecordingsVC = savedVC
        mixerVC.view.translatesAutoresizingMaskIntoConstraints = true
        savedRecordingsVC.view.translatesAutoresizingMaskIntoConstraints = true
        
        // 1) Add the central Recording VC – always visible.
        addChild(recordingVC)
        recordingVC.view.frame = view.bounds
        view.addSubview(recordingVC.view)
        recordingVC.didMove(toParent: self)
        
        // 2) Add the Mixer VC off-screen to the right.
        addChild(mixerVC)
        let containerWidth = view.bounds.width
        mixerVC.view.frame = view.bounds.offsetBy(dx: containerWidth, dy: 0)
        mixerVC.view.translatesAutoresizingMaskIntoConstraints = true  // Allow manual frame changes.
        view.addSubview(mixerVC.view)
        mixerVC.didMove(toParent: self)
        
        // 3) Add the Saved Recordings VC off-screen to the left.
        addChild(savedRecordingsVC)
        savedRecordingsVC.view.frame = view.bounds.offsetBy(dx: -containerWidth, dy: 0)
        savedRecordingsVC.view.translatesAutoresizingMaskIntoConstraints = true  // Allow manual frame changes.
        view.addSubview(savedRecordingsVC.view)
        savedRecordingsVC.didMove(toParent: self)
        
        // Make sure the recording interface is always on top.
        view.bringSubviewToFront(recordingVC.view)
        
        // 4) Set up the pan gesture recognizer.
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self // Allow simultaneous gesture recognition.
        view.addGestureRecognizer(panGesture)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let containerWidth = view.bounds.width
        print("Pan translation.x: \(translation.x)")
        
        switch gesture.state {
        case .changed:
            if translation.x > 0 {
                // Swiping right: reveal the saved recordings panel (from left)
                let newX = min(-containerWidth + translation.x, 0)
                savedRecordingsVC.view.frame.origin.x = newX
            } else if translation.x < 0 {
                // Swiping left: reveal the mixer panel (from right)
                let targetX = containerWidth * (1 - overlayFraction)
                let newX = max(containerWidth + translation.x, targetX)
                mixerVC.view.frame.origin.x = newX
            }
            
        case .ended, .cancelled:
            if translation.x > 0 {
                // Decide for saved recordings.
                if translation.x > containerWidth * 0.3 {
                    UIView.animate(withDuration: 0.3) {
                        self.savedRecordingsVC.view.frame.origin.x = 0
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.savedRecordingsVC.view.frame.origin.x = -containerWidth
                    }
                }
            } else if translation.x < 0 {
                // Decide for mixer.
                if abs(translation.x) > containerWidth * 0.3 {
                    let targetX = containerWidth * (1 - overlayFraction)
                    UIView.animate(withDuration: 0.3) {
                        self.mixerVC.view.frame.origin.x = targetX
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.mixerVC.view.frame.origin.x = containerWidth
                    }
                }
            }
            // Reset translation.
            gesture.setTranslation(.zero, in: view)
            
        default:
            break
        }
    }
    
    // Allow simultaneous gesture recognition.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
