//
//  CameraView.swift
//  FLEXIVE
//
//  Created by 油木さくら on 2026/02/08.
//


import SwiftUI

struct CameraView: View {
    @StateObject private var vm = CameraViewModel()
    
    var body: some View {
        ZStack {
            // カメラプレビュー（背景）
            CameraPreview(session: vm.session)
                .edgesIgnoringSafeArea(.all)
            
            // 検出された体のスケルトン（緑色）
            SkeletonOverlayView(joints: vm.joints, color: .green)
                .edgesIgnoringSafeArea(.all)
            
            // ターゲットポーズのスケルトン（青色・半透明）
            SkeletonOverlayView(joints: vm.template.joints, color: .blue.opacity(0.5))
                .frame(width: 300, height: 500)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        }
        .onAppear { vm.start() }
        .fullScreenCover(isPresented: $vm.showResult) {
            ResultView(point: vm.point) {
                vm.nextPose()
            }
        }
    }
}
