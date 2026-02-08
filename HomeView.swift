import SwiftUI

struct HomeView: View {
    @State private var navigateToBodyCheck = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.6, blue: 1.0),
                        Color(red: 0.6, green: 0.4, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("🤸‍♂️")
                            .font(.system(size: 80))
                        
                        Text("Let's start\nbeing flexible!")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    
                    Button(action: {
                        navigateToBodyCheck = true
                    }) {
                        HStack {
                            Text("START")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.mint]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(35)
                        .shadow(color: .green.opacity(0.5), radius: 15, x: 0, y: 5)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(destination: BodyCheckView(), isActive: $navigateToBodyCheck) {
                    EmptyView()
                }
                .hidden()
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
