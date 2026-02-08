import Foundation
import AVFoundation
import Vision

@MainActor
class GameViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published var poseTimeRemaining: Double = 10
    @Published var gameEnded = false
    @Published var lastPoseCleared = false

    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var totalTimer: Timer?
    private var poseTimer: Timer?

    override init() {
        super.init()
        setupCamera()
    }

    // MARK: - Game Control

    func startGame() {
        captureSession.startRunning()
        startTimers()
        selectRandomPose()
    }

    func stopGame() {
        captureSession.stopRunning()
        totalTimer?.invalidate()
        poseTimer?.invalidate()
        gameEnded = true
    }

    func resetGame() {
        poseTimeRemaining = 10
        gameEnded = false
        lastPoseCleared = false
        startGame()
    }

    // MARK: - Camera

    private func setupCamera() {
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else { return }

        captureSession.addInput(input)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }

    // MARK: - Timer

    private func startTimers() {
        poseTimer?.invalidate()

        poseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }

            self.poseTimeRemaining -= 1

            if self.poseTimeRemaining <= 0 {
                self.poseTimeRemaining = 10
                self.selectRandomPose()
            }
        }
    }

    // MARK: - Pose

    private func selectRandomPose() {
        // 仮の処理（あとでポーズロジック追加）
        lastPoseCleared.toggle()
    }
}
