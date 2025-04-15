import UIKit
import AVFoundation

class WaveformView: UIView {
    var level: Float = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    weak var recorder: AVAudioRecorder?
    private var displayLink: CADisplayLink?
    private var levels: [Float] = Array(repeating: 0.0, count: 30)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isHidden = true
    }

    func startMonitoring() {
        self.isHidden = false
        self.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }

        displayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopMonitoring() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
        }) { _ in
            self.isHidden = true
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }

    @objc private func updateMeter() {
        guard let recorder = recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let avgPower = recorder.averagePower(forChannel: 0)
        let normalizedPower = max(0.0, (avgPower + 60) / 60) // Normalize to 0–1
        level = normalizedPower

        levels.removeFirst()
        levels.append(normalizedPower)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        let barWidth: CGFloat = rect.width / CGFloat(levels.count)
        let maxHeight = rect.height

        for (index, level) in levels.enumerated() {
            let barHeight = CGFloat(level) * maxHeight
            let x = CGFloat(index) * barWidth
            let y = (maxHeight - barHeight) / 2
            let barRect = CGRect(x: x, y: y, width: barWidth * 0.8, height: barHeight)

            let colorAlpha = CGFloat(index) / CGFloat(levels.count)
            let color = UIColor.systemTeal.withAlphaComponent(colorAlpha)
            context.setFillColor(color.cgColor)

            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth * 0.4)
            context.addPath(path.cgPath)
            context.fillPath()
        }
    }
}
