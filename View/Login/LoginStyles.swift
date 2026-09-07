//
//  LoginStyles.swift
//  PixelNOW
//
//  Created by Jayian on 6/14/26.
//

import SwiftUI

extension Font {
    static func nvidiaSans(size: CGFloat, weight: NVIDIAFont.Weight = .regular) -> Font {
        NVIDIAFont.font(size: size, weight: weight)
    }
}

struct LoginTextFieldStyle: TextFieldStyle {
    let isFocused: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(.white)
            .tint(Color.pixelNowGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .overlay {
                Rectangle()
                    .stroke(isFocused ? Color.pixelNowGreen : Color.gfnStroke, lineWidth: isFocused ? 2 : 1)
            }
    }
}

struct PrimaryLoginButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.black)
            .tracking(0.4)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? Color.pixelNowGreen.opacity(0.76) : Color.pixelNowGreen)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct VendorGetInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.nvidiaSans(size: 14, weight: .bold))
            .foregroundStyle(.black)
            .tracking(0.3)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(configuration.isPressed ? Color.pixelNowGreen.opacity(0.78) : Color.pixelNowGreen)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct VendorProviderPickerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white.opacity(configuration.isPressed ? 0.16 : 0.08))
            .overlay {
                Rectangle()
                    .stroke(configuration.isPressed ? Color.pixelNowGreen.opacity(0.75) : Color.gfnStroke, lineWidth: 1)
            }
    }
}

struct SecondaryLoginButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 13 : 14, weight: .bold))
            .foregroundStyle(.white)
            .tracking(0.3)
            .padding(.horizontal, compact ? 14 : 16)
            .padding(.vertical, compact ? 8 : 12)
            .background(Color.white.opacity(configuration.isPressed ? 0.16 : 0.08))
            .overlay {
                Rectangle()
                    .stroke(Color.gfnStroke, lineWidth: 1)
            }
    }
}

extension Color {
    static let pixelNowBlue = Color(red: 0.08, green: 0.48, blue: 0.98)
    static let pixelNowGreen = pixelNowBlue // Kept for complete symbol compatibility with new PlayStation blue palette
    static let gfnBackgroundGreen = Color(red: 8 / 255, green: 14 / 255, blue: 29 / 255)
    static let gfnPanel = Color(red: 17 / 255, green: 26 / 255, blue: 48 / 255)
    static let gfnCharcoal = Color(red: 5 / 255, green: 8 / 255, blue: 20 / 255)
    static let gfnStroke = Color.white.opacity(0.12)
    static let gfnTextSecondary = Color.white.opacity(0.72)
    static let gfnTextTertiary = Color.white.opacity(0.48)
}
