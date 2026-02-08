import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            // カメラプレビュー
            if viewModel.isCameraActive {
                CameraPreview(session: viewModel.captureSession)
                    .ignoresSafeArea()
            } else {
                // カメラがオフのときは黒い背景を表示
                Color.black.ignoresSafeArea()
            }

            // ユーザーのスケルトン
            SkeletonOverlayView(joints: viewModel.userJoints, color: .green)
                .ignoresSafeArea()

            VStack {
                // --- 上部UIエリア ---
                HStack(alignment: .top) {
                    // お題ポーズ表示エリア
                    VStack {
                        Text("MODEL POSE")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(viewModel.currentPoseTemplate.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 4)

                        // お題のスケルトン
                        SkeletonOverlayView(joints: viewModel.currentPoseTemplate.joints, color: .cyan)
                            .frame(width: 150, height: 250)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)

                    Spacer()

                    // スコア表示エリア
                    VStack {
                        Text("SCORE")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(String(format: "%.1f", viewModel.score * 100))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor(score: viewModel.score))
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                .padding(.top, 50)

                Spacer()

                // --- 下部UIエリア ---
                Button(action: {
                    viewModel.loadNextPose()
                }) {
                    HStack {
                        Text("Next Pose")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
    
    // スコアに応じて色を変更するヘルパー関数
    private func scoreColor(score: Double) -> Color {
        if score > 0.8 {
            return .green
        } else if score > 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}