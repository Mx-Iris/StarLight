import SwiftUI
import Luminare

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Welcome to StarLight")
                .font(.largeTitle)
            Button {
                
            } label: {
                Text("Login")
            }
            .buttonStyle(LuminareCompactButtonStyle())
            .frame(width: 80, height: 30)
        }
    }
}

@available(macOS 14.0, *)
#Preview {
    LoginView()
        .frame(width: 550, height: 300)
}
