import SwiftUI
import AVFoundation
import Vision

struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession
    @ObservedObject var viewModel: BodyCheckViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear   // ← 実は clear より安全

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .landscapeRight

        let skeletonLayer = CAShapeLayer()
        skeletonLayer.strokeColor = UIColor.green.cgColor
        skeletonLayer.lineWidth = 3
        skeletonLayer.fillColor = UIColor.clear.cgColor

        view.layer.addSublayer(previewLayer)
        view.layer.addSublayer(skeletonLayer)

        context.coordinator.previewLayer = previewLayer
        context.coordinator.skeletonLayer = skeletonLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = context.coordinator.previewLayer,
              let skeletonLayer = context.coordinator.skeletonLayer
        else { return }

        // 🔥 ここがないと映らない
        previewLayer.frame = uiView.bounds
        skeletonLayer.frame = uiView.bounds

        // ===== skeleton 描画 =====
        let path = UIBezierPath()

        func p(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let pt = viewModel.currentJoints[joint] else { return nil }

            return CGPoint(
                x: pt.x * uiView.bounds.width,
                y: (1 - pt.y) * uiView.bounds.height
            )
        }


        func line(_ a: VNHumanBodyPoseObservation.JointName,
                  _ b: VNHumanBodyPoseObservation.JointName) {
            guard let p1 = p(a), let p2 = p(b) else { return }
            path.move(to: p1)
            path.addLine(to: p2)
        }

        // hi
        line(.leftShoulder, .leftElbow)
        line(.leftElbow, .leftWrist)
        line(.rightShoulder, .rightElbow)
        line(.rightElbow, .rightWrist)
        line(.leftHip, .leftKnee)
        line(.leftKnee, .leftAnkle)
        line(.rightHip, .rightKnee)
        line(.rightKnee, .rightAnkle)

        skeletonLayer.path = path.cgPath
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
        var skeletonLayer: CAShapeLayer?
    }
}

