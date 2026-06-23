import SwiftUI

struct SkeletonModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 0 : 1)
            .overlay {
                if isActive {
                    SkeletonShimmerView()
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
    }
}

struct SkeletonShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    Color(.tertiarySystemFill).opacity(0.6),
                    Color(.quaternarySystemFill).opacity(0.8),
                    Color(.tertiarySystemFill).opacity(0.6)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 3)
            .offset(x: -geo.size.width + (phase * geo.size.width * 2))
            .animation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: phase
            )
        }
        .onAppear { phase = 1.0 }
        .clipped()
    }
}

extension View {
    func skeleton(_ isActive: Bool) -> some View {
        modifier(SkeletonModifier(isActive: isActive))
    }
}

struct SkeletonText: View {
    let width: CGFloat?
    let height: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .frame(width: width, height: height)
            .overlay(SkeletonShimmerView())
            .clipShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
    }
}

struct SkeletonCircle: View {
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(Color(.tertiarySystemFill))
            .frame(width: size, height: size)
            .overlay(SkeletonShimmerView())
            .clipShape(Circle())
    }
}

struct SkeletonCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(SkeletonShimmerView())
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct PlantSkeletonView: View {
    let size: CGFloat
    
    init(size: CGFloat = 200) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.tertiarySystemFill).opacity(0.3))
                .frame(width: size * 0.8, height: size * 0.8)
            
            VStack(spacing: size * 0.05) {
                Circle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: size * 0.3, height: size * 0.3)
                
                HStack(spacing: size * 0.08) {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: size * 0.2, height: size * 0.2)
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: size * 0.25, height: size * 0.25)
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: size * 0.2, height: size * 0.2)
                }
                
                RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: size * 0.06, height: size * 0.25)
            }
        }
        .frame(width: size, height: size)
        .overlay(SkeletonShimmerView())
        .clipShape(Circle().scale(0.9))
    }
}

struct BloomLaunchScreen: View {
    @State private var animate = false
    @State private var showLogo = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.bloomPrimary.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animate ? 1.0 : 0.5)
                        .opacity(animate ? 1 : 0)
                    
                    Text("🌱")
                        .font(.system(size: 80))
                        .scaleEffect(showLogo ? 1.0 : 0.3)
                        .opacity(showLogo ? 1 : 0)
                }
                
                Text("Bloom")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bloomPrimary)
                    .opacity(showLogo ? 1 : 0)
                    .offset(y: showLogo ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animate = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showLogo = true
            }
        }
    }
}

struct GardenViewSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PlantSkeletonView(size: 240)
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
                
                SkeletonCard()
                    .frame(height: 120)
                    .padding(.horizontal, 20)
                
                SkeletonCard()
                    .frame(height: 80)
                    .padding(.horizontal, 20)
                
                SkeletonCard()
                    .frame(height: 160)
                    .padding(.horizontal, 20)
                
                SkeletonCard()
                    .frame(height: 200)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L.myGarden)
        .navigationBarTitleDisplayMode(.large)
    }
}
