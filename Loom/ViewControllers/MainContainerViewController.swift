import UIKit

class MainContainerViewController: UIViewController {

    // Child view controllers
    var recordingVC: RecordingViewController!
    var mixerVC: MixerViewController!
    var savedRecordingsVC: SavedRecordingsViewController!
    
    // Pan gesture recognizer
    var panGesture: UIPanGestureRecognizer!
    
    // The fraction of the screen the side panel overlays when fully revealed.
    let overlayFraction: CGFloat = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate child view controllers from Main.storyboard using their Storyboard IDs.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let recVC = storyboard.instantiateViewController(withIdentifier: "RecordingViewController") as? RecordingViewController,
              let mixVC = storyboard.instantiateViewController(withIdentifier: "MixerViewController") as? MixerViewController,
              let savedVC = storyboard.instantiateViewController(withIdentifier: "SavedRecordingsViewController") as? SavedRecordingsViewController
        else {
            fatalError("One or more child view controllers could not be instantiated from the storyboard. Check your Storyboard IDs and custom classes.")
        }
        
        recordingVC = recVC
        mixerVC = mixVC
        savedRecordingsVC = savedVC
        
        // Add the central Recording VC – always visible.
        addChild(recordingVC)
        recordingVC.view.frame = view.bounds
        view.addSubview(recordingVC.view)
        recordingVC.didMove(toParent: self)
        
        // Add the Mixer VC, positioned off-screen to the right.
        addChild(mixerVC)
        let containerWidth = view.bounds.width
        mixerVC.view.frame = view.bounds.offsetBy(dx: containerWidth, dy: 0)
        view.addSubview(mixerVC.view)
        mixerVC.didMove(toParent: self)
        
        // Add the Saved Recordings VC, positioned off-screen to the left.
        addChild(savedRecordingsVC)
        savedRecordingsVC.view.frame = view.bounds.offsetBy(dx: -containerWidth, dy: 0)
        view.addSubview(savedRecordingsVC.view)
        savedRecordingsVC.didMove(toParent: self)
        
        // Bring the central recording VC's view to the front.
        view.bringSubviewToFront(recordingVC.view)
        
        // Add pan gesture recognizer to handle swipes.
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let containerWidth = view.bounds.width
        
        switch gesture.state {
        case .changed:
            if translation.x > 0 {
                // Swipe right: reveal saved recordings (from left)
                let newX = min(-containerWidth + translation.x, 0)
                savedRecordingsVC.view.frame.origin.x = newX
            } else if translation.x < 0 {
                // Swipe left: reveal mixer (from right)
                // Target position when fully revealed: containerWidth * (1 - overlayFraction)
                let targetX = containerWidth * (1 - overlayFraction)
                let newX = max(containerWidth + translation.x, targetX)
                mixerVC.view.frame.origin.x = newX
            }
            
        case .ended, .cancelled:
            // When the pan ends, decide whether to snap in the side panel or retract it
            if translation.x > 0 {
                // Saved Recordings side
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
                // Mixer side
                if abs(translation.x) > containerWidth * 0.3 {
                    let targetX = containerWidth * (1 - self.overlayFraction)
                    UIView.animate(withDuration: 0.3) {
                        self.mixerVC.view.frame.origin.x = targetX
                    }
                } else {
                    UIView.animate(withDuration: 0.3) {
                        self.mixerVC.view.frame.origin.x = containerWidth
                    }
                }
            }
            gesture.setTranslation(.zero, in: view)
            
        default:
            break
        }
    }
}
