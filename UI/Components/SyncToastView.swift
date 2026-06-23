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

enum SyncProgressStep: Equatable {
    case downloading
    case merging
    case uploading
    
    var title: String {
        switch self {
        case .downloading: return NSLocalizedString("下载中", comment: "Downloading")
        case .merging: return NSLocalizedString("合并中", comment: "Merging")
        case .uploading: return NSLocalizedString("上传中", comment: "Uploading")
        }
    }
    
    var index: Int {
        switch self {
        case .downloading: return 0
        case .merging: return 1
        case .uploading: return 2
        }
    }
}

struct SyncToastView: View {
    let state: SyncToastState
    let onDismiss: () -> Void
    var progress: SyncProgressStep = .downloading
    var canRetry: Bool = false
    var showsSettings: Bool = false
    var onRetry: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                toastContent
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        if case .success = state {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
            } else {
                if isVisible {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var toastContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                icon
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                Spacer()
                actionButton
            }
            
            if case .syncing = state {
                progressIndicator
            }
            
            if case .failed = state, (canRetry || showsSettings) {
                actionButtons
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
    
    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach([SyncProgressStep.downloading, .merging, .uploading], id: \.self) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(step.index <= progress.index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(step.title)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(step.index <= progress.index ? 1 : 0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            if canRetry {
                Button {
                    onRetry?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text(NSLocalizedString("重试", comment: "Retry"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            if showsSettings {
                Button {
                    onOpenSettings?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(NSLocalizedString("去设置", comment: "Go to Settings"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
        }
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
    
    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .failed:
            if !canRetry && !showsSettings {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        default:
            EmptyView()
        }
    }

    private var title: String {
        switch state {
        case .idle:          return ""
        case .syncing:       return NSLocalizedString("同步中...", comment: "Syncing")
        case .success:      return NSLocalizedString("同步完成", comment: "Sync completed")
        case .failed:        return NSLocalizedString("同步失败", comment: "Sync failed")
        }
    }

    private var subtitle: String {
        switch state {
        case .idle:          return ""
        case .syncing:       return NSLocalizedString("正在同步数据到 iCloud", comment: "Syncing data to iCloud")
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
