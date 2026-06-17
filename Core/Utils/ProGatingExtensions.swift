//
//  ProGatingExtensions.swift
//  水滴花园 (Bloom)
//
//  Pro feature gating utilities
//

import SwiftUI

// MARK: - Pro Required Navigation Modifier

extension View {
    /// Shows paywall if user is not Pro, otherwise navigates normally
    func proRequiredNavigationModifier<Paywall: View>(
        isPro: Bool,
        @ViewBuilder paywall: @escaping () -> Paywall
    ) -> some View {
        self.modifier(ProRequiredNavigationModifier(isPro: isPro, paywall: paywall))
    }
}

struct ProRequiredNavigationModifier<Paywall: View>: ViewModifier {
    let isPro: Bool
    let paywall: () -> Paywall
    
    @State private var showPaywall = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !isPro {
                            showPaywall = true
                        }
                    }
            )
            .sheet(isPresented: $showPaywall) {
                paywall()
            }
    }
}

// MARK: - Pro Badge Helper

extension View {
    /// Add Pro badge if feature requires Pro
    func proBadge(_ isPro: Bool) -> some View {
        self.overlay(
            Group {
                if !isPro {
                    Text("Pro")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color.bloomPrimary, Color.bloomGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
        )
    }
}
