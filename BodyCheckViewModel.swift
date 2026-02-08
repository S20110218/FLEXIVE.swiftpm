import Foundation
import AVFoundation
import Vision

@MainActor
class BodyCheckViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    // ===== Body Check 用 =====
    @Published var checkItems: [PoseCheckItem] = [
        PoseCheckItem(name: "頭 (Head)", joint: .nose),
        PoseCheckItem(name: "左腕 (Left Arm)", joint: .leftWrist),
        PoseCheckItem(name: "右腕 (Right Arm)", joint: .rightWrist),
        PoseCheckItem(name: "左足 (Left Leg)", joint: .leftAnkle),
        PoseCheckItem(name: "右足 (Right Leg)", joint: .rightAnkle)
    ]

    @Published var completionPercentage: Double = 0
    @Published var isComplete: Bool = false

    // ===== 骨格描画用（CameraPreviewView が使う）=====
    @Published var currentJoints: [VNHumanBodyPoseObservation.JointName : CGPoint] = [:]

    // ===== Camera =====
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    override init() {
        super.init()
        setupCamera()
    }

    // MARK: - Camera Control

    func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high

        // フロントカメラ
        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .front),
            let input = try? AVCaptureDeviceInput(device: camera)
        else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Video Output
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        // ★ Delegate はバックグラウンドキュー
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "BodyCheckVideoQueue")
        )

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Capture Delegate
    
    // Sendableな構造体を作る
    struct JointData: Sendable {
        let name: VNHumanBodyPoseObservation.JointName
        let location: CGPoint
        let confidence: Float
    }


    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])

        try? handler.perform([request])
        guard let observation = request.results?.first else { return }

        // ★ Sendableに変換
        let joints: [JointData] = observation.availableJointNames.compactMap { jointName in
            guard let point = try? observation.recognizedPoint(jointName) else { return nil }
            return JointData(name: jointName,
                             location: point.location,
                             confidence: point.confidence)
        }

        Task { @MainActor [weak self] in
            self?.applyObservationResult(joints: joints)
        }
    }


    // MARK: - Pose Processing
    private func applyObservationResult(joints: [JointData]) {

        // ===== 骨格描画用 =====
        currentJoints = Dictionary(uniqueKeysWithValues:
            joints.map { ($0.name, $0.location) }
        )

        // ===== 検出済みJoint =====
        let detectedJoints = joints
            .filter { $0.confidence > 0.3 }
            .map { $0.name }

        // ===== チェック更新 =====
        for index in checkItems.indices {
            if detectedJoints.contains(checkItems[index].joint) {
                checkItems[index].isDetected = true
            }
        }

        let detectedCount = checkItems.filter { $0.isDetected }.count
        completionPercentage = Double(detectedCount) / Double(checkItems.count) * 100
        isComplete = detectedCount == checkItems.count
    }


}
