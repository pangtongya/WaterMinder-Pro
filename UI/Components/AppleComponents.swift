import SwiftUI

struct SurfaceCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.bloomSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.bloomCardBorder, lineWidth: 0.5)
            )
    }
}

enum BadgeStyle {
    case brand
    case water
    case gold
    case fill
    case success
    case warning
    case error
    case info

    var backgroundColor: Color {
        switch self {
        case .brand: return Color.bloomPrimaryMuted
        case .water: return Color.bloomWaterMuted
        case .gold: return Color.bloomGoldMuted
        case .fill: return Color.bloomFill
        case .success: return Color.bloomSuccess.opacity(0.15)
        case .warning: return Color.bloomWarning.opacity(0.15)
        case .error: return Color.bloomError.opacity(0.15)
        case .info: return Color.bloomInfo.opacity(0.12)
        }
    }

    var textColor: Color {
        switch self {
        case .brand: return Color.bloomPrimary
        case .water: return Color.bloomWater
        case .gold: return Color.bloomGold
        case .fill: return Color.bloomTextSecondary
        case .success: return Color.bloomSuccess
        case .warning: return Color.bloomWarning
        case .error: return Color.bloomError
        case .info: return Color.bloomInfo
        }
    }
}

struct Badge: View {
    let text: String
    let style: BadgeStyle

    init(_ text: String, style: BadgeStyle = .brand) {
        self.text = text
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.22)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(style.backgroundColor)
            .foregroundStyle(style.textColor)
            .clipShape(Capsule())
    }
}

enum IconCircleSize {
    case small
    case medium

    var dimension: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        }
    }
}

struct IconCircle: View {
    let icon: String
    let backgroundColor: Color
    let iconColor: Color
    let size: IconCircleSize

    init(icon: String, backgroundColor: Color, iconColor: Color, size: IconCircleSize = .medium) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.size = size
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size == .small ? 16 : 20, weight: .regular))
            .foregroundStyle(iconColor)
            .frame(width: size.dimension, height: size.dimension)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

struct IconCircleSmall: View {
    let icon: String
    let backgroundColor: Color
    let iconColor: Color

    init(icon: String, backgroundColor: Color, iconColor: Color) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }

    var body: some View {
        IconCircle(icon: icon, backgroundColor: backgroundColor, iconColor: iconColor, size: .small)
    }
}

struct ProgressRing<Content: View>: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let centerContent: Content

    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 180,
        backgroundColor: Color = .bloomFill,
        foregroundColor: Color = .bloomPrimary,
        @ViewBuilder centerContent: () -> Content = { EmptyView() }
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.centerContent = centerContent()
    }

    private var circumference: CGFloat {
        .pi * (size - lineWidth)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            centerContent
        }
    }
}

struct LargeTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(Color.bloomPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
        }
    }
}

struct SegmentedPicker: View {
    @Binding var selection: String
    let options: [String]
    var fullWidth: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                    Haptics.light()
                } label: {
                    Text(option)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selection == option ? Color.bloomTextPrimary : Color.bloomTextSecondary)
                        .frame(maxWidth: fullWidth ? .infinity : nil)
                        .padding(.horizontal, fullWidth ? 0 : 12)
                        .padding(.vertical, 6)
                        .fixedSize(horizontal: !fullWidth, vertical: false)
                        .background(
                            selection == option ?
                            Color.bloomSurface :
                            Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: selection == option ? Color.black.opacity(0.08) : Color.clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.bloomFill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(_ title: String, action: (() -> Void)? = nil, actionTitle: String? = nil) {
        self.title = title
        self.action = action
        self.actionTitle = actionTitle
    }

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.22)
                .foregroundStyle(Color.bloomTextSecondary)

            Spacer()

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.bloomPrimary)
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconBackground: Color
    let iconColor: Color
    let title: String
    let value: String?
    let showChevron: Bool
    let isOn: Bool?
    let showsDivider: Bool
    let action: (() -> Void)?

    init(
        icon: String,
        iconBackground: Color = .bloomPrimaryMuted,
        iconColor: Color = .bloomPrimary,
        title: String,
        value: String? = nil,
        showChevron: Bool = true,
        isOn: Bool? = nil,
        showsDivider: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconBackground = iconBackground
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.showChevron = showChevron
        self.isOn = isOn
        self.showsDivider = showsDivider
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { action?() }) {
                HStack(spacing: 12) {
                    IconCircle(
                        icon: icon,
                        backgroundColor: iconBackground,
                        iconColor: iconColor,
                        size: .medium
                    )

                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.bloomTextPrimary)

                    Spacer()

                    if let isOn = isOn {
                        Toggle("", isOn: .constant(isOn))
                            .labelsHidden()
                            .tint(Color.bloomPrimary)
                    } else if let value = value {
                        Text(value)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.bloomTextSecondary)
                    }

                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.bloomTextTertiary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            if showsDivider {
                Rectangle()
                    .fill(Color.bloomDivider)
                    .frame(height: 0.5)
                    .padding(.leading, 68)
                    .padding(.trailing, 16)
            }
        }
    }
}

struct HealthStatusBar: View {
    let health: Double
    let showLabel: Bool

    init(health: Double, showLabel: Bool = true) {
        self.health = health
        self.showLabel = showLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showLabel {
                HStack {
                    Text("健康度")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomPrimary)

                    Spacer()

                    Text("\(Int(health))%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.bloomPrimary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bloomFill)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bloomPrimary)
                        .frame(width: geometry.size.width * (health / 100))
                        .animation(.easeInOut(duration: 0.4), value: health)
                }
            }
            .frame(height: 8)
        }
    }
}

struct GrowthProgressBar: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("成长进度")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextTertiary)

                Spacer()

                Text("\(Int(progress))%")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextTertiary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.bloomFill)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.bloomWater)
                        .frame(width: geometry.size.width * (progress / 100))
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct StreakBadge: View {
    let days: Int
    let showBadge: Bool

    init(days: Int, showBadge: Bool = true) {
        self.days = days
        self.showBadge = showBadge
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 16))

            Text("连续 \(days) 天")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.bloomTextPrimary)

            if showBadge {
                Badge("里程碑", style: .brand)
            }
        }
    }
}

struct WaterRecordRow: View {
    let amount: Int
    let cupType: String
    let time: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            IconCircle(
                icon: icon,
                backgroundColor: Color.bloomWaterMuted,
                iconColor: Color.bloomWater,
                size: .small
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(amount)ml")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.bloomTextPrimary)

                Text(cupType)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextTertiary)
            }

            Spacer()

            Text(time)
                .font(.system(size: 14))
                .foregroundStyle(Color.bloomTextSecondary)
        }
        .padding(.vertical, 12)
    }
}

struct CupSizeButton: View {
    let amount: Int
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            Haptics.light()
        }) {
            VStack(spacing: 4) {
                IconCircle(
                    icon: icon,
                    backgroundColor: Color.bloomWaterMuted,
                    iconColor: Color.bloomWater,
                    size: .medium
                )

                Text("\(amount)ml")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.bloomTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct ProgressCapsule: View {
    let remaining: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "droplets")
                .font(.system(size: 14))
                .foregroundStyle(Color.bloomWater)

            Text("还差 \(remaining) ml")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.bloomWater)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.bloomPrimarySubtle)
        .clipShape(Capsule())
    }
}

struct StatsCard: View {
    let stats: [(icon: String, value: String, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                VStack(spacing: 4) {
                    Text(stat.icon)
                        .font(.system(size: 24))

                    Text(stat.value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bloomTextPrimary)

                    Text(stat.label)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.bloomTextSecondary)
                }
                .frame(maxWidth: .infinity)

                if index < stats.count - 1 {
                    Divider()
                        .frame(maxHeight: .infinity)
                        .background(Color.bloomDivider)
                }
            }
        }
    }
}

struct ProFeatureCard: View {
    let title: String
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Badge("PRO", style: .gold)

                Spacer()
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.bloomTextPrimary)
        }
        .padding(16)
        .background(Color.bloomSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.bloomCardBorder, lineWidth: 0.5)
        )
        .overlay(alignment: .center) {
            if !isUnlocked {
                Color.bloomSurface.opacity(0.6)
                    .blur(radius: 2)
            }
        }
    }
}

struct SpeciesCard: View {
    let name: String
    let icon: String
    let status: SpeciesStatus
    let isCollected: Bool

    enum SpeciesStatus {
        case collected
        case proLocked
        case locked
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 48, height: 48)

                if isCollected {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(iconColor)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.bloomTextTertiary)
                }
            }

            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isCollected ? Color.bloomTextPrimary : Color.bloomTextSecondary)
                .lineLimit(1)

            statusBadge
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.bloomSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(status == .locked ? 0.5 : 1.0)
    }

    private var backgroundColor: Color {
        if isCollected {
            return Color.bloomPrimary.opacity(0.15)
        }
        return Color.bloomFill
    }

    private var iconColor: Color {
        switch status {
        case .collected: return Color.bloomPrimary
        case .proLocked: return Color.bloomWarning
        case .locked: return Color.bloomTextTertiary
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .collected:
            Badge("已收集", style: .brand)
        case .proLocked:
            Badge("Pro 解锁", style: .gold)
        case .locked:
            Badge("未收集", style: .fill)
        }
    }
}

struct HarvestedPlantCard: View {
    let name: String
    let species: String
    let days: Int
    let icon: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }

            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.bloomTextPrimary)
                .lineLimit(1)

            Text("\(species) · 成熟")
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextSecondary)
                .lineLimit(1)

            Text("\(days) 天收获")
                .font(.system(size: 11))
                .foregroundStyle(Color.bloomTextTertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bloomSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
