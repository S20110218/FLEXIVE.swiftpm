import SwiftUI

struct TimerBox: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(value)s")
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}
