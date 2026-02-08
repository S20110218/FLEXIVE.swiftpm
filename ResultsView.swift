import SwiftUI

struct ResultsView: View {
    let score: Int
    let clearCount: Int
    let onHome: () -> Void
    let onNextRoutine: () -> Void
    
    @StateObject private var recordsManager = GameRecordsManager()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.6),
                    Color(red: 0.4, green: 0.2, blue: 0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Text("🎊")
                            .font(.system(size: 60))
                        
                        Text("Game Over!")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        ResultCard(title: "Final Score", value: "\(score)", icon: "star.fill", color: .yellow)
                        ResultCard(title: "Clear Count", value: "\(clearCount)", icon: "checkmark.circle.fill", color: .green)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.5))
                        .padding(.vertical, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("🏆 Past Records")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if recordsManager.records.isEmpty {
                            Text("まだ記録がありません")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(recordsManager.records.enumerated()), id: \.element.id) { index, record in
                                    RecordRow(rank: index + 1, record: record)
                                }
                            }
                            .padding(.trailing, 120)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            
            VStack(spacing: 15) {
                Button(action: onNextRoutine) {
                    HStack {
                        Text("Next\nRoutine")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 130)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.mint]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                
                Button(action: onHome) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
            .padding(20)
        }
        .onAppear {
            recordsManager.addRecord(score: score, clearCount: clearCount)
        }
    }
}
