// WaterRecordModel.swift
// 喝水记录数据模型

import Foundation

struct WaterRecordModel: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var amount: Int
    var cupType: CupType
    var note: String?
    
    var isCompleted: Bool {
        amount > 0
    }
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        amount: Int,
        cupType: CupType = .medium,
        note: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.amount = amount
        self.cupType = cupType
        self.note = note
    }
    
    // MARK: - Computed Properties
    
    var amountInLiters: Double {
        Double(amount) / 1000.0
    }
    
    var formattedAmount: String {
        if amount >= 1000 {
            return String(format: "%.1fL", amountInLiters)
        } else {
            return "\(amount)ml"
        }
    }
    
    var timeString: String {
        Self.timeFormatter.string(from: createdAt)
    }
    
    var dateString: String {
        Self.dateFormatter.string(from: createdAt)
    }
    
    // MARK: - Static Formatters (避免重复创建)
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - CupType Enum
enum CupType: String, CaseIterable, Codable {
    case small = "小杯"
    case medium = "中杯"
    case large = "大杯"
    case bottle = "水瓶"
    
    var icon: String {
        switch self {
        case .small:  return "cup.and.saucer.fill"
        case .medium: return "mug.fill"
        case .large:  return "takeoutbag.and.cup.and.straw.fill"
        case .bottle: return "waterbottle.fill"
        }
    }
    
    var defaultAmount: Int {
        switch self {
        case .small:  return 200
        case .medium: return 350
        case .large:  return 500
        case .bottle: return 750
        }
    }
    
    var description: String {
        "\(rawValue) (\(defaultAmount)ml)"
    }
}

// MARK: - Equatable
extension WaterRecordModel {
    static func == (lhs: WaterRecordModel, rhs: WaterRecordModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.amount == rhs.amount &&
        lhs.cupType == rhs.cupType &&
        lhs.createdAt == rhs.createdAt &&
        lhs.note == rhs.note
    }
}
