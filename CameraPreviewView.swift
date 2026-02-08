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
        // 縦向き（ポートレート）に設定
        view.previewLayer.connection?.videoOrientation = .portrait

        context.coordinator.previewLayer = view.previewLayer
        context.coordinator.skeletonLayer = view.skeletonLayer
        context.coordinator.containerView = view

        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        // スケルトン描画を即座に更新
        context.coordinator.updateSkeleton(with: viewModel.currentJoints, bounds: uiView.bounds)
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var skeletonLayer: CAShapeLayer?
        weak var containerView: PreviewContainerView?
        
        func updateSkeleton(with joints: [VNHumanBodyPoseObservation.JointName : CGPoint], bounds: CGRect) {
            guard let skeletonLayer = skeletonLayer else { return }
            
            // 空のjointsの場合は早期リターン
            guard !joints.isEmpty else {
                skeletonLayer.path = nil
                return
            }
            
            // 座標変換関数（内カメラ縦向き用）
            func transformPoint(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
                guard let pt = joints[joint] else { return nil }
                // Vision座標系からUIKit座標系に変換（内カメラ縦向き）
                return CGPoint(
                    x: pt.x * bounds.width,
                    y: (1 - pt.y) * bounds.height
                )
            }
            
            // パスを作成
            let path = UIBezierPath()
            
            // 関節を描画する関数
            func drawJoint(_ joint: VNHumanBodyPoseObservation.JointName, radius: CGFloat = 8) {
                guard let point = transformPoint(joint) else { return }
                path.move(to: CGPoint(x: point.x + radius, y: point.y))
                path.addArc(withCenter: point, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            }
            
            // 線を描画するヘルパー関数
            func drawLine(from a: VNHumanBodyPoseObservation.JointName,
                         to b: VNHumanBodyPoseObservation.JointName) {
                guard let p1 = transformPoint(a),
                      let p2 = transformPoint(b) else { return }
                path.move(to: p1)
                path.addLine(to: p2)
            }
            
            // === 骨格の線を描画 ===
            
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
            
            // 首・頭
            drawLine(from: .neck, to: .nose)
            
            // 左脚
            drawLine(from: .leftHip, to: .leftKnee)
            drawLine(from: .leftKnee, to: .leftAnkle)
            
            // 右脚
            drawLine(from: .rightHip, to: .rightKnee)
            drawLine(from: .rightKnee, to: .rightAnkle)
            
            // === 関節の円を描画 ===
            drawJoint(.nose)
            drawJoint(.neck)
            drawJoint(.leftShoulder)
            drawJoint(.rightShoulder)
            drawJoint(.leftElbow)
            drawJoint(.rightElbow)
            drawJoint(.leftWrist)
            drawJoint(.rightWrist)
            drawJoint(.leftHip)
            drawJoint(.rightHip)
            drawJoint(.leftKnee)
            drawJoint(.rightKnee)
            drawJoint(.leftAnkle)
            drawJoint(.rightAnkle)
            
            // パスを即座に設定（アニメーション無し）
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
        
        // スケルトンレイヤーの設定
        skeletonLayer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.9).cgColor
        skeletonLayer.lineWidth = 5
        skeletonLayer.fillColor = UIColor.systemGreen.withAlphaComponent(0.4).cgColor
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
        
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }
}
