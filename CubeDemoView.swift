import SwiftUI

struct CubeDemoView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            InteractiveCubeView()
                .ignoresSafeArea()
                .accessibilityLabel("Interactive cube")
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    CubeDemoView()
}

