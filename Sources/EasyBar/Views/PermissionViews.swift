import SwiftUI

struct PermissionAlertView: View {
    @Binding var isPresented: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Accessibility Permission Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("EasyBar needs Accessibility permission to manage menu bar icons. Please grant permission in System Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            HStack(spacing: 16) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Open Settings") {
                    onOpenSettings()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 400)
    }
}

struct PermissionStatusView: View {
    let isAuthorized: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isAuthorized ? .green : .red)
            Text(isAuthorized ? "Accessibility Granted" : "Accessibility Not Granted")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
