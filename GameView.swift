import SwiftUI

struct GameView: View {
    
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            
            // ポーズカード
            VStack(spacing: 16) {
                
                Text("MODEL")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.7), .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 260)
                    .overlay(
                        Text(viewModel.currentPose.rawValue)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                Text("Score: \(viewModel.totalScore)")
                    .foregroundColor(.white)
                
                Text("Clear: \(viewModel.clearCount)")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(24)
            
            Spacer()
            
            // ボタン
            HStack(spacing: 16) {
                Button("START") { viewModel.startGame() }
                    .buttonStyle(.borderedProminent)
                
                Button("STOP") { viewModel.stopGame() }
                    .buttonStyle(.bordered)
                
                Button("RESET") { viewModel.resetGame() }
                    .buttonStyle(.bordered)
            }
            
            Button("BACK") { dismiss() }
                .padding(.top, 8)
        }
    }
}
