import Foundation
import Vision

enum GamePose: String, CaseIterable {
    case armsUp = "Arms Up ✋"
    case armsOut = "Arms Out →←"
    case oneLegUp = "One Leg Up 🦵"
    case squat = "Squat Down ⬇️"
    case tPose = "T-Pose 🤸"
    case jumpingJack = "Jumping Jack ⭐"
    
    var description: String {
        switch self {
        case .armsUp: return "両腕を上に伸ばす"
        case .armsOut: return "両腕を横に伸ばす"
        case .oneLegUp: return "片足を上げる"
        case .squat: return "スクワット姿勢"
        case .tPose: return "T字ポーズ"
        case .jumpingJack: return "ジャンピングジャック"
        }
    }
    
    func calculateScore(observation: VNHumanBodyPoseObservation) -> Int {
        switch self {
        case .armsUp:
            return scoreArmsUp(observation)
        case .armsOut:
            return scoreArmsOut(observation)
        case .oneLegUp:
            return scoreOneLegUp(observation)
        case .squat:
            return scoreSquat(observation)
        case .tPose:
            return scoreTPose(observation)
        case .jumpingJack:
            return scoreJumpingJack(observation)
        }
    }
    
    private func scoreArmsUp(_ obs: VNHumanBodyPoseObservation) -> Int {
        guard let leftWrist = try? obs.recognizedPoint(.leftWrist),
              let rightWrist = try? obs.recognizedPoint(.rightWrist),
              let leftShoulder = try? obs.recognizedPoint(.leftShoulder),
              let rightShoulder = try? obs.recognizedPoint(.rightShoulder),
              leftWrist.confidence > 0.3, rightWrist.confidence > 0.3,
              leftShoulder.confidence > 0.3, rightShoulder.confidence > 0.3 else {
            return 0
        }
        
        var score = 0
        
        if leftWrist.location.y > leftShoulder.location.y { score += 10 }
        if rightWrist.location.y > rightShoulder.location.y { score += 10 }
        
        let heightDiff = abs(leftWrist.location.y - rightWrist.location.y)
        if heightDiff < 0.1 { score += 10 }
        
        if score >= 20 { score += 10 }
        
        return min(score, 40)
    }
    
    private func scoreArmsOut(_ obs: VNHumanBodyPoseObservation) -> Int {
        guard let leftWrist = try? obs.recognizedPoint(.leftWrist),
              let rightWrist = try? obs.recognizedPoint(.rightWrist),
              let leftShoulder = try? obs.recognizedPoint(.leftShoulder),
              let rightShoulder = try? obs.recognizedPoint(.rightShoulder),
              leftWrist.confidence > 0.3, rightWrist.confidence > 0.3 else {
            return 0
        }
        
        var score = 0
        
        let armSpan = abs(leftWrist.location.x - rightWrist.location.x)
        if armSpan > 0.4 { score += 15 }
        
        let leftHeight = abs(leftWrist.location.y - leftShoulder.location.y)
        let rightHeight = abs(rightWrist.location.y - rightShoulder.location.y)
        if leftHeight < 0.15 { score += 10 }
        if rightHeight < 0.15 { score += 10 }
        
        if score >= 25 { score += 5 }
        
        return min(score, 40)
    }
    
    private func scoreOneLegUp(_ obs: VNHumanBodyPoseObservation) -> Int {
        guard let leftKnee = try? obs.recognizedPoint(.leftKnee),
              let rightKnee = try? obs.recognizedPoint(.rightKnee),
              let leftHip = try? obs.recognizedPoint(.leftHip),
              let rightHip = try? obs.recognizedPoint(.rightHip),
              leftKnee.confidence > 0.3, rightKnee.confidence > 0.3 else {
            return 0
        }
        
        var score = 0
        
        let leftKneeHeight = leftKnee.location.y - leftHip.location.y
        let rightKneeHeight = rightKnee.location.y - rightHip.location.y
        
        if leftKneeHeight > 0.15 || rightKneeHeight > 0.15 {
            score += 20
        }
        
        let kneeDiff = abs(leftKnee.location.y - rightKnee.location.y)
        if kneeDiff > 0.2 { score += 15 }
        
        if score >= 30 { score += 5 }
        
        return min(score, 40)
    }
    
    private func scoreSquat(_ obs: VNHumanBodyPoseObservation) -> Int {
        guard let leftKnee = try? obs.recognizedPoint(.leftKnee),
              let rightKnee = try? obs.recognizedPoint(.rightKnee),
              let leftHip = try? obs.recognizedPoint(.leftHip),
              let rightHip = try? obs.recognizedPoint(.rightHip),
              leftKnee.confidence > 0.3, rightKnee.confidence > 0.3 else {
            return 0
        }
        
        var score = 0
        
        let leftDistance = abs(leftKnee.location.y - leftHip.location.y)
        let rightDistance = abs(rightKnee.location.y - rightHip.location.y)
        
        if leftDistance < 0.25 { score += 15 }
        if rightDistance < 0.25 { score += 15 }
        
        let kneeDiff = abs(leftKnee.location.y - rightKnee.location.y)
        if kneeDiff < 0.1 { score += 10 }
        
        return min(score, 40)
    }
    
    private func scoreTPose(_ obs: VNHumanBodyPoseObservation) -> Int {
        return scoreArmsOut(obs)
    }
    
    private func scoreJumpingJack(_ obs: VNHumanBodyPoseObservation) -> Int {
        var score = scoreArmsOut(obs)
        
        if let leftAnkle = try? obs.recognizedPoint(.leftAnkle),
           let rightAnkle = try? obs.recognizedPoint(.rightAnkle),
           leftAnkle.confidence > 0.3, rightAnkle.confidence > 0.3 {
            let footSpan = abs(leftAnkle.location.x - rightAnkle.location.x)
            if footSpan > 0.3 { score += 5 }
        }
        
        return min(score, 40)
    }
}
