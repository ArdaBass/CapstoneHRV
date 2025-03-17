import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDisabled ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: configuration.isPressed ? 0 : 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
            .padding(.horizontal) // ✅ Merged from extension
    }
}

extension Button {
    func primaryButtonStyle(disabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isDisabled: disabled))
    }
}

