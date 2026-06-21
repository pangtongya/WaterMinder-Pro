// HelpView.swift
// 帮助与反馈页面

import SwiftUI
import MessageUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    
    var body: some View {
        NavigationStack {
            List {
                // 使用指南
                Section(header: Text("使用指南")) {
                    NavigationLink {
                        UsageGuideView()
                    } label: {
                        Label("快速入门", systemImage: "book.fill")
                            .foregroundStyle(Color.bloomPrimary)
                    }
                    
                    NavigationLink {
                        FAQView()
                    } label: {
                        Label("常见问题", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(Color.bloomPrimary)
                    }
                }
                
                // 反馈
                Section(header: Text("反馈")) {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showMailComposer = true
                        } else {
                            // 设备不支持邮件，复制邮箱地址
                            UIPasteboard.general.string = "support@bloom.app"
                        }
                    } label: {
                        Label("联系支持", systemImage: "envelope.fill")
                            .foregroundStyle(Color.bloomPrimary)
                    }
                    
                    Button {
                        if let url = URL(string: "https://bloom.app/feedback") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("去官网反馈", systemImage: "globe")
                            .foregroundStyle(Color.bloomPrimary)
                    }
                }
                
                // 关于
                Section(header: Text("关于")) {
                    HStack {
                        Label("版本", systemImage: "info.circle.fill")
                            .foregroundStyle(Color.bloomPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("帮助与反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    subject: "Bloom App 反馈",
                    recipients: ["support@bloom.app"],
                    result: $mailResult
                )
            }
        }
    }
}

// MARK: - 使用指南

struct UsageGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                guideSection(
                    icon: "drop.fill",
                    title: "记录喝水",
                    description: "点击主界面的大杯子或快速记录按钮，即可记录喝水。向左滑动记录可以删除。"
                )
                
                guideSection(
                    icon: "leaf.fill",
                    title: "照顾植物",
                    description: "每次喝水后，植物会获得水分并成长。如果长时间不喝水，植物会枯萎。"
                )
                
                guideSection(
                    icon: "star.fill",
                    title: "解锁成就",
                    description: "坚持喝水可以解锁成就，收集成就徽章！"
                )
                
                guideSection(
                    icon: "square.grid.2x2.fill",
                    title: "收获植物",
                    description: "植物成熟后可以收获，放入花园收藏。免费用户最多保存 5 株植物。"
                )
                
                guideSection(
                    icon: "icloud.fill",
                    title: "iCloud 同步",
                    description: "开启 iCloud 同步后，你的数据会在所有设备上自动同步。"
                )
            }
            .padding()
        }
        .navigationTitle("快速入门")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func guideSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.bloomPrimary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - 常见问题

struct FAQView: View {
    @State private var expandedIndex: Int? = nil
    
    let faqs = [
        ("如何修改每日饮水目标？", "在设置页面 → 饮水目标，可以调整每日目标量。"),
        ("如何开启提醒？", "在设置页面 → 提醒，可以设置提醒间隔和时间段。"),
        ("如何同步到健康 App？", "在设置页面 → 健康 App，点击「连接健康 App」并授权。"),
        ("如何升级到 Pro？", "在设置页面点击「升级到 Pro」，或点击任意 Pro 功能。"),
        ("如何备份数据？", "在设置页面 → 数据备份与恢复，可以导出备份文件。"),
        ("为什么植物枯萎了？", "如果长时间不喝水，植物会逐渐枯萎。及时喝水可以恢复健康！")
    ]
    
    var body: some View {
        List {
            ForEach(faqs.indices, id: \.self) { index in
                FAQRow(
                    question: faqs[index].0,
                    answer: faqs[index].1,
                    isExpanded: expandedIndex == index
                ) {
                    withAnimation {
                        expandedIndex = expandedIndex == index ? nil : index
                    }
                }
            }
        }
        .navigationTitle("常见问题")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(result: $result)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var result: Binding<Result<MFMailComposeResult, Error>?>
        
        init(result: Binding<Result<MFMailComposeResult, Error>?>) {
            self.result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                self.result.wrappedValue = .failure(error)
            } else {
                self.result.wrappedValue = .success(result)
            }
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    HelpView()
}
