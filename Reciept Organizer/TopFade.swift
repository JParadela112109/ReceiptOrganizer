import SwiftUI

struct TopFade: View {
    var color: Color = Color(.systemBackground)
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: color, location: 0),
                .init(color: color.opacity(0.0), location: 1)
            ]),
            startPoint: .top, endPoint: .bottom
        )
        .frame(height: 60)
        .ignoresSafeArea(edges: .top)
    }
} 