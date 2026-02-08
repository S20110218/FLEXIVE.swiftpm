import SwiftUI
import AVFoundation
import Vision

struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession
    @ObservedObject var viewModel: BodyCheckViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.backgroundColor = .black

        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.connection?.videoOrientation = .landscapeRight

        context.coordinator.previewLayer = view.previewLayer
        context.coordinator.skeletonLayer = view.skeletonLayer
        context.coordinator.containerView = view

        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        // スケルトン描画を最適化
        context.coordinator.updateSkeleton(with: viewModel.currentJoints)
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var skeletonLayer: CAShapeLayer?
        weak var containerView: PreviewContainerView?
        
        // 座標変換をキャッシュ
        private var lastBounds: CGRect = .zero
        
        func updateSkeleton(with joints: [VNHumanBodyPoseObservation.JointName : CGPoint]) {
            guard let skeletonLayer = skeletonLayer,
                  let view = containerView else { return }
            
            let bounds = view.bounds
            
            // 空のjointsの場合は早期リターン
            guard !joints.isEmpty else {
                skeletonLayer.path = nil
                return
            }
            
            // 座標変換関数（最適化版）
            func transformPoint(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
                guard let pt = joints[joint] else { return nil }
                return CGPoint(
                    x: pt.x * bounds.width,
                    y: (1 - pt.y) * bounds.height
                )
            }
            
            // パスを作成
            let path = UIBezierPath()
            
            // 線を描画するヘルパー関数
            func drawLine(from a: VNHumanBodyPoseObservation.JointName,
                         to b: VNHumanBodyPoseObservation.JointName) {
                guard let p1 = transformPoint(a),
                      let p2 = transformPoint(b) else { return }
                path.move(to: p1)
                path.addLine(to: p2)
            }
            
            // 左腕
            drawLine(from: .leftShoulder, to: .leftElbow)
            drawLine(from: .leftElbow, to: .leftWrist)
            
            // 右腕
            drawLine(from: .rightShoulder, to: .rightElbow)
            drawLine(from: .rightElbow, to: .rightWrist)
            
            // 体幹
            drawLine(from: .leftShoulder, to: .rightShoulder)
            drawLine(from: .leftShoulder, to: .leftHip)
            drawLine(from: .rightShoulder, to: .rightHip)
            drawLine(from: .leftHip, to: .rightHip)
            
            // 左脚
            drawLine(from: .leftHip, to: .leftKnee)
            drawLine(from: .leftKnee, to: .leftAnkle)
            
            // 右脚
            drawLine(from: .rightHip, to: .rightKnee)
            drawLine(from: .rightKnee, to: .rightAnkle)
            
            // パスを設定（アニメーション無し）
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            skeletonLayer.path = path.cgPath
            CATransaction.commit()
        }
    }
}

final class PreviewContainerView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()
    let skeletonLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // プレビューレイヤーの設定
        previewLayer.backgroundColor = UIColor.black.cgColor
        
        // スケルトンレイヤーの設定（最適化）
        skeletonLayer.strokeColor = UIColor.green.cgColor
        skeletonLayer.lineWidth = 4
        skeletonLayer.fillColor = UIColor.clear.cgColor
        skeletonLayer.lineCap = .round
        skeletonLayer.lineJoin = .round
        
        layer.addSublayer(previewLayer)
        layer.addSublayer(skeletonLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        skeletonLayer.frame = bounds
    }
}
