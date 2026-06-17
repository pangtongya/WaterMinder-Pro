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
                Text("\(plant.name) 已成熟！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // 植物信息
                VStack(spacing: 12) {
                    HStack {
                        Text("阶段:")
                            .foregroundColor(.secondary)
                        Text(plant.stage.name)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("健康度:")
                            .foregroundColor(.secondary)
                        Text("\(Int(plant.health))%")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("天数:")
                            .foregroundColor(.secondary)
                        Text("\(plant.ageInDays) 天")
                            .fontWeight(.semibold)
                    }
                }
                .font(.system(size: 16))
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Text("恭喜！你的植物已经成长到 \(plant.stage.name) 阶段")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // 收获按钮
                Button("收获并保存到收藏") {
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
            .navigationTitle("收获植物")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HarvestView(
        plant: Plant(name: "小绿", stage: .mature, health: 95),
        onHarvest: {}
    )
}
