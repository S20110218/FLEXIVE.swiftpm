import SwiftUI
import Vision

struct SkeletonOverlayView: View {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let color: Color
    
    private let links: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // 左腕
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        
        // 右腕
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        
        // 体幹
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip),
        (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        
        // 首・頭
        (.neck, .nose),
        
        // 左脚
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        
        // 右脚
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 線を描画
                ForEach(links, id: \.0) { a, b in
                    if let p1 = joints[a], let p2 = joints[b] {
                        Path { path in
                            path.move(to: CGPoint(
                                x: p1.x * geo.size.width,
                                y: p1.y * geo.size.height
                            ))
                            path.addLine(to: CGPoint(
                                x: p2.x * geo.size.width,
                                y: p2.y * geo.size.height
                            ))
                        }
                        .stroke(color, lineWidth: 4)
                    }
                }
                
                // 関節の円を描画
                ForEach(Array(joints.keys), id: \.self) { joint in
                    if let point = joints[joint] {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                            .position(
                                x: point.x * geo.size.width,
                                y: point.y * geo.size.height
                            )
                    }
                }
            }
        }
    }
}
