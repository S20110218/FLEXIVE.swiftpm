import SwiftUI

struct GameView: View {
    
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            
            // ポーズ表示カード
            VStack(spacing: 12) {
                Text("MODEL")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 240)
                    .overlay(
                        Text(viewModel.currentPose.rawValue)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )
                
                Text("Score: \(viewModel.totalScore)")
                    .foregroundColor(.white)
                
                Text("Clear: \(viewModel.clearCount)")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(20)
            
            Spacer()
            
            // 操作ボタン
            HStack(spacing: 20) {
                Button("START") {
                    viewModel.startGame()
                }
                .buttonStyle(.borderedProminent)
                
                Button("STOP") {
                    viewModel.stopGame()
                }
                .buttonStyle(.bordered)
                
                Button("RESET") {
                    viewModel.resetGame()
                }
                .buttonStyle(.bordered)
            }
            
            Button("BACK") {
                dismiss()
            }
            .padding(.top, 10)
        }
    }
}
