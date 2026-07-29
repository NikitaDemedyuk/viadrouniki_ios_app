import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Retry") {
                Task { await retry() }
            }
            .font(.footnote)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
