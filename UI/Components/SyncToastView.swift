// SyncToastView.swift
// iCloud 同步状态 Toast
//
// 显示在屏幕顶部的临时横幅，用于告知用户同步状态变化。

import SwiftUI

enum SyncToastState: Equatable {
    case idle
    case syncing       // 正在同步
    case success(Date) // 同步成功
    case failed(String) // 同步失败（携带错误信息）

    static func == (lhs: SyncToastState, rhs: SyncToastState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.syncing, .syncing): return true
        case (.success(let a), .success(let b)): return a == b
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

struct SyncToastView: View {
    let state: SyncToastState
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                toastContent
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // 自动消失：成功 3 秒后 / 失败需要用户手动关闭
                        if case .success = state {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                dismiss()
                            }
                        }
                    }
            }
            Spacer()
        }
        .animation(.spring(response: 0.35), value: isVisible)
        .onChange(of: state) { _, newValue in
            if newValue != .idle {
                withAnimation { isVisible = true }
            }
        }
    }

    @ViewBuilder
    private var toastContent: some View {
        HStack(spacing: 10) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            if case .failed = state {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toastColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var icon: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .syncing:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 20)
    }

    private var title: String {
        switch state {
        case .idle:          return ""
        case .syncing:       return NSLocalizedString("同步中...", comment: "Syncing")
        case .success:      return NSLocalizedString("iCloud 同步成功", comment: "iCloud sync success")
        case .failed(let e): return NSLocalizedString("iCloud 同步失败", comment: "iCloud sync failed")
        }
    }

    private var subtitle: String {
        switch state {
        case .idle:          return ""
        case .syncing:       return NSLocalizedString("正在保存数据到 iCloud", comment: "Saving data to iCloud")
        case .success:       return NSLocalizedString("你的数据已同步到所有设备", comment: "Data synced to all devices")
        case .failed(let e): return e
        }
    }

    private var toastColor: Color {
        switch state {
        case .idle:    return .clear
        case .syncing: return Color.orange
        case .success: return Color.bloomSuccess
        case .failed:  return Color.bloomWarning
        }
    }

    private func dismiss() {
        withAnimation { isVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview("Success") {
    SyncToastView(state: .success(Date())) { }
}

// 确保 .bloomSuccess / .bloomWarning 颜色已定义（定义在 BloomColors.swift）
// 如果未定义，使用 fallback：
#if !canImport(BloomColors)
import SwiftUI
extension Color {
    static let bloomSuccess = Color(hex: "#66BB6A")
    static let bloomWarning = Color(hex: "#FFA726")
}
#endif
