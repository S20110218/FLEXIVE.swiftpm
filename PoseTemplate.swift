import Vision
import CoreGraphics

struct PoseTemplate {
    let name: String
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
}
