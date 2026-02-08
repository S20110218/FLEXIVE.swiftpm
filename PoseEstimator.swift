import Vision
import AVFoundation

final class PoseEstimator {

    private let request = VNDetectHumanBodyPoseRequest()

    func process(sampleBuffer: CMSampleBuffer,
                 completion: @escaping ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void) {

        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            completion([:])
            return
        }

        // 内カメラ縦向き用の設定
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored)

        do {
            try handler.perform([request])
        } catch {
            completion([:])
            return
        }

        guard let obs = request.results?.first else {
            completion([:])
            return
        }

        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

        let names: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .neck,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]

        for joint in names {
            guard let p = try? obs.recognizedPoint(joint), p.confidence > 0.3 else { continue }
            // Vision座標系(左下原点)からUIKit座標系(左上原点)に変換
            joints[joint] = CGPoint(x: p.location.x, y: 1 - p.location.y)
        }

        completion(joints)
    }

    // MARK: - Score
    func score(current: [VNHumanBodyPoseObservation.JointName: CGPoint],
               target: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> Double {

        var total: CGFloat = 0
        var count: CGFloat = 0

        for (joint, targetPoint) in target {
            guard let currentPoint = current[joint] else { continue }
            let distance = hypot(currentPoint.x - targetPoint.x, currentPoint.y - targetPoint.y)
            total += distance
            count += 1
        }

        guard count > 0 else { return 0 }

        let avg = total / count

        // 距離が小さいほど高スコア（0.0 ~ 1.0）
        return max(0, 1 - Double(avg * 2))
    }
}
