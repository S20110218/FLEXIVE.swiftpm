//
//  CameraViewModel.swift
//  FLEXIVE
//
//  Created by 油木さくら on 2026/02/08.
//


import SwiftUI
import AVFoundation
import Vision

@MainActor
final class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Published
    @Published var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var template: PoseTemplate = PoseTemplateRepository.shared.random()
    @Published var showResult: Bool = false
    @Published var point: Int = 0
    
    // MARK: - Camera
    let session = AVCaptureSession()
    nonisolated(unsafe) private let estimator = PoseEstimator()
    
    // MARK: - Start Camera
    func start() {
        session.beginConfiguration()
        
        // 内カメラ（フロントカメラ）
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .front),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        
        // セッション開始
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    // MARK: - Capture Delegate
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        
        estimator.process(sampleBuffer: sampleBuffer) { [weak self] detected in
            Task { @MainActor [weak self] in
                self?.joints = detected
                self?.checkPose()
            }
            
            
        }
    }
    
    // MARK: - Pose Check
    private func checkPose() {
        let score = estimator.score(current: joints, target: template.joints)
        
        if score > 0.8 {
            point = Int(score * 100)
            showResult = true
        }
    }
    
    // MARK: - Next Pose
    func nextPose() {
        template = PoseTemplateRepository.shared.random()
        showResult = false
    }
}
