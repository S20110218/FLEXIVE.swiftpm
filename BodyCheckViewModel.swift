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
    
    // Vision リクエストを再利用
    nonisolated(unsafe) private let poseRequest = VNDetectHumanBodyPoseRequest()

    override init() {
        super.init()
        poseRequest.revision = VNDetectHumanBodyPoseRequestRevision1
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

        // フロントカメラ（内カメラ）
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
        
        // 遅延フレームを破棄
        videoOutput.alwaysDiscardsLateVideoFrames = true

        // ★ 高優先度キューで処理
        let videoQueue = DispatchQueue(label: "BodyCheckVideoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

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

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // リクエストハンドラーを作成（内カメラの縦向きに対応）
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,  // 内カメラ縦向き用
            options: [:]
        )

        // リクエストを実行
        try? handler.perform([self.poseRequest])
        
        guard let observation = self.poseRequest.results?.first else { return }

        // ★ 全ての検出可能な関節を取得
        let joints: [JointData] = observation.availableJointNames.compactMap { jointName in
            guard let point = try? observation.recognizedPoint(jointName),
                  point.confidence > 0.2 else { return nil }
            return JointData(
                name: jointName,
                location: point.location,
                confidence: point.confidence
            )
        }

        // メインスレッドで即座に更新
        Task { @MainActor [weak self] in
            self?.applyObservationResult(joints: joints)
        }
    }

    // MARK: - Pose Processing
    private func applyObservationResult(joints: [JointData]) {

        // ===== 骨格描画用（辞書を一度だけ作成）=====
        let newJoints = Dictionary(uniqueKeysWithValues:
            joints.map { ($0.name, $0.location) }
        )
        
        // 即座に更新
        self.currentJoints = newJoints

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
