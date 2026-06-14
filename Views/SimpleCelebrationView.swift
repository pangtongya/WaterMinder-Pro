// SimpleCelebrationView.swift
// 简单庆祝视图 - 达成目标时显示对勾和文字

import SwiftUI

struct SimpleCelebrationView: View {
    let onDismiss: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        onDismiss()
                    }
                }
            
            // 内容
            VStack(spacing: 24) {
                // 对勾圆圈
                ZStack {
                    Circle()
                        .stroke(Color.green, lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    if showContent {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // 文字
                if showContent {
                    VStack(spacing: 8) {
                        Text("🎉 恭喜！")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("你已完成今日饮水目标")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

#Preview {
    SimpleCelebrationView {
        print("Dismissed")
    }
    .background(Color.gray)
}
