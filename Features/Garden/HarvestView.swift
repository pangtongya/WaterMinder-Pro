// HarvestView.swift
// 收获植物视图 - 庆祝植物成熟并保存到收藏

import SwiftUI

struct HarvestView: View {
    let plant: Plant
    let onHarvest: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // 庆祝图标
                Text("🎉")
                    .font(.system(size: 80))
                
                // 标题
                Text(String(format: NSLocalizedString("%@ 已成熟！", comment: ""), plant.name))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // 植物信息
                VStack(spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("阶段:", comment: "Stage:"))
                            .foregroundColor(.secondary)
                        Text(plant.stage.name)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text(L.health)
                            .foregroundColor(.secondary)
                        Text("\(Int(plant.health))%")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text(NSLocalizedString("天数:", comment: "Days:"))
                            .foregroundColor(.secondary)
                        Text(String(format: NSLocalizedString("%d 天", comment: ""), plant.ageInDays))
                            .fontWeight(.semibold)
                    }
                }
                .font(.system(size: 16))
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Text(String(format: NSLocalizedString("恭喜！你的植物已经成长到 %@ 阶段", comment: ""), plant.stage.name))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // 收获按钮
                Button(NSLocalizedString("收获并保存到收藏", comment: "Harvest and save")) {
                    onHarvest()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.bloomPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding()
            .navigationTitle(NSLocalizedString("收获植物", comment: "Harvest plant"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
