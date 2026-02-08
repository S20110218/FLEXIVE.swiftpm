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
    
    // フレームスキップ用（パフォーマンス改善）
    private var frameCount = 0
    private let processEveryNFrames = 2 // 2フレームに1回処理

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

        // Video Output（最適化）
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        // フレームレートを制限してパフォーマンス向上
        videoOutput.alwaysDiscardsLateVideoFrames = true

        // ★ Delegate はバックグラウンドキュー
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "BodyCheckVideoQueue", qos: .userInitiated)
        )

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Capture Delegate
    
    // Sendableな構造体
    struct JointData: Sendable {
        let name: VNHumanBodyPoseObservation.JointName
        let location: CGPoint
        let confidence: Float
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {

        // フレームスキップでパフォーマンス改善
        let currentFrame = self.incrementFrameCount()
        guard currentFrame % self.processEveryNFrames == 0 else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPoseRequest()
        request.revision = VNDetectHumanBodyPoseRequestRevision1
        
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        try? handler.perform([request])
        guard let observation = request.results?.first else { return }

        // ★ Sendableに変換（必要な関節のみ）
        let requiredJoints: Set<VNHumanBodyPoseObservation.JointName> = [
            .nose, .leftWrist, .rightWrist, .leftAnkle, .rightAnkle,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftHip, .rightHip, .leftKnee, .rightKnee
        ]
        
        let joints: [JointData] = observation.availableJointNames.compactMap { jointName in
            guard requiredJoints.contains(jointName),
                  let point = try? observation.recognizedPoint(jointName),
                  point.confidence > 0.3 else { return nil }
            return JointData(
                name: jointName,
                location: point.location,
                confidence: point.confidence
            )
        }

        Task { @MainActor [weak self] in
            self?.applyObservationResult(joints: joints)
        }
    }
    
    private nonisolated func incrementFrameCount() -> Int {
        // スレッドセーフなカウンター
        OSAtomicIncrement32Barrier(&unsafeBitCast(self, to: UnsafeMutablePointer<Int32>.self).pointee)
        return Int(unsafeBitCast(self, to: UnsafePointer<Int32>.self).pointee)
    }

    // MARK: - Pose Processing
    private func applyObservationResult(joints: [JointData]) {

        // ===== 骨格描画用（辞書を一度だけ作成）=====
        currentJoints = Dictionary(uniqueKeysWithValues:
            joints.map { ($0.name, $0.location) }
        )

        // ===== 検出済みJoint（Set で高速化）=====
        let detectedJointNames = Set(joints.map { $0.name })

        // ===== チェック更新 =====
        for index in checkItems.indices {
            if detectedJointNames.contains(checkItems[index].joint) {
                checkItems[index].isDetected = true
            }
        }

        let detectedCount = checkItems.filter { $0.isDetected }.count
        completionPercentage = Double(detectedCount) / Double(checkItems.count) * 100
        isComplete = detectedCount == checkItems.count
    }
}
