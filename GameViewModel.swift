import Foundation
import AVFoundation

@MainActor
class GameViewModel: NSObject, ObservableObject {

    // MARK: - Pose
    enum PoseType: String, CaseIterable {
        case tPose = "T-POSE"
        case handsUp = "HANDS UP"
        case squat = "SQUAT"
    }

    // MARK: - Published
    @Published var currentPose: PoseType = .tPose
    @Published var totalScore: Int = 0
    @Published var clearCount: Int = 0
    @Published var poseTimeRemaining: Double = 10
    @Published var gameEnded: Bool = false

    // MARK: - Camera
    let captureSession = AVCaptureSession()

    // MARK: - Timer
    private var poseTimer: Timer?

    // MARK: - Init
    override init() {
        super.init()
        setupCamera()
    }

    // MARK: - Game Control
    func startGame() {
        captureSession.startRunning()
        startPoseTimer()
        selectRandomPose()
    }

    func stopGame() {
        captureSession.stopRunning()
        poseTimer?.invalidate()
        gameEnded = true
    }

    func resetGame() {
        totalScore = 0
        clearCount = 0
        poseTimeRemaining = 10
        gameEnded = false
        startGame()
    }

    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else { return }

        captureSession.addInput(input)
    }

    // MARK: - Timer
    private func startPoseTimer() {
        poseTimer?.invalidate()

        poseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }

            self.poseTimeRemaining -= 1

            if self.poseTimeRemaining <= 0 {
                self.poseTimeRemaining = 10
                self.totalScore += 10
                self.clearCount += 1
                self.selectRandomPose()
            }
        }
    }

    // MARK: - Pose Logic
    private func selectRandomPose() {
        currentPose = PoseType.allCases.randomElement() ?? .tPose
    }
}
