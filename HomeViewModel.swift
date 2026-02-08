import Foundation
import AVFoundation
import Vision
import Combine

@MainActor
class HomeViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Published Properties
    @Published var userJoints: [VNHumanBodyPoseObservation.JointName : CGPoint] = [:]
    @Published var currentPoseTemplate: PoseTemplate
    @Published var score: Double = 0.0
    @Published var isCameraActive = false

    // MARK: - Camera Properties
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    nonisolated private let poseEstimator = PoseEstimator()
    nonisolated private let poseRepository = PoseTemplateRepository.shared
    
    // Visionリクエスト
    private let poseRequest = VNDetectHumanBodyPoseRequest()

    override init() {
        // 初期ポーズをランダムに設定
        self.currentPoseTemplate = poseRepository.random()
        super.init()
        setupCamera()
    }
    
    // MARK: - Public Methods
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isCameraActive = true
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isCameraActive = false
            }
        }
    }
    
    func loadNextPose() {
        self.currentPoseTemplate = poseRepository.random()
        self.score = 0.0 // スコアをリセット
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let videoQueue = DispatchQueue(label: "HomeVideoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        poseEstimator.process(sampleBuffer: sampleBuffer) { [weak self] detectedJoints in
            guard let self = self else { return }
            
            let newScore = self.poseEstimator.score(current: detectedJoints, target: self.currentPoseTemplate.joints)
            
            // メインスレッドでUIを更新
            DispatchQueue.main.async {
                self.userJoints = detectedJoints
                self.score = newScore
            }
        }
    }
}
