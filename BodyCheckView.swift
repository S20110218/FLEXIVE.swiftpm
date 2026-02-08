import SwiftUI

struct BodyCheckView: View {

    @StateObject private var viewModel = BodyCheckViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToGame = false

    var body: some View {
        NavigationStack {
            ZStack {
                
                // 🔴 背景：カメラ映像 + skeleton
                CameraPreviewView(
                    session: viewModel.captureSession,
                    viewModel: viewModel
                )
                .ignoresSafeArea()
                
                // 🔴 上に乗せるUI
                VStack(spacing: 20) {
                    
                    Text("Body Check")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    Text("全身を画面に収めてください")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // チェックリスト
                    VStack(spacing: 12) {
                        ForEach(viewModel.checkItems) { item in
                            HStack {
                                Image(systemName: item.isDetected
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                .foregroundColor(item.isDetected ? .green : .white.opacity(0.5))
                                
                                Text(item.name)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.4))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // 進捗
                    Text("\(Int(viewModel.completionPercentage))%")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                }
                NavigationLink(destination: GameView(),
                               isActive: $navigateToGame) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
            
            // 🔴 カメラ起動（これが無いと黒）
            .onAppear {
                viewModel.startSession()
            }
            
            .onDisappear {
                viewModel.stopSession()
            }
            
            .onChange(of: viewModel.isComplete) { complete in
                if complete {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToGame = true
                    }
                }
            }
            
            .background(
                NavigationLink(destination: GameView(),
                               isActive: $navigateToGame) {
                                   EmptyView()
                               }
                    .hidden()
            )
        }
    }
}

