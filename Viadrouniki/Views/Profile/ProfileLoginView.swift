import SwiftUI

struct ProfileLoginView: View {
    @State private var viewModel = ProfileLoginViewModel()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Sign in to Viadrouniki")
                    .font(.title2.bold())
                Text("Use Google to sign in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            googleButton
                .padding(.top, 32)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var googleButton: some View {
        Button {
            Task { await viewModel.signInWithGoogle() }
        } label: {
            HStack(spacing: 12) {
                Image("google")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Sign in with Google")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(Color("googleButtonLabel"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color("googleButtonSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("googleButtonBorder"), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSigningIn)
    }
}

#Preview {
    ProfileLoginView()
        .environment(AppViewModel())
}
