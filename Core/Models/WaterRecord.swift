// WaterRecord.swift
// 喝水记录模型 —— 植物的"水分"，也是用户行为的唯一凭证

import Foundation

struct WaterRecord: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let createdAt: Date
    let amount: Int          // 毫升
    let cupType: CupType
    /// 来自 HealthKit 的样本 UUID（用于去重，避免同一健康记录被重复写入）
    var hkSampleUUID: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        amount: Int,
        cupType: CupType = .medium,
        hkSampleUUID: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.amount = amount
        self.cupType = cupType
        self.hkSampleUUID = hkSampleUUID
    }

    // MARK: - 格式化

    var formattedAmount: String {
        amount >= 1000 ? String(format: "%.1fL", Double(amount) / 1000.0) : "\(amount)ml"
    }

    var timeString: String { Self.timeFormatter.string(from: createdAt) }
    var dateString: String { Self.dateFormatter.string(from: createdAt) }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - CupType 杯型

enum CupType: String, CaseIterable, Codable {
    case small  = "小杯"
    case medium = "中杯"
    case large  = "大杯"
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
}

// MARK: - 数据验证

extension WaterRecord: Validatable {
    func validate() throws {
        guard amount >= 50 && amount <= 5000 else {
            throw PersistenceError.validationFailed(
                "WaterRecord",
                "Invalid amount: \(amount)ml (must be 50-5000ml)"
            )
        }
        guard createdAt <= Date().addingTimeInterval(60) else {
            throw PersistenceError.validationFailed(
                "WaterRecord",
                "Future date detected: \(createdAt)"
            )
        }
        guard id != UUID() || id.uuidString.count > 0 else {
            throw PersistenceError.validationFailed(
                "WaterRecord",
                "Invalid UUID"
            )
        }
    }
}
