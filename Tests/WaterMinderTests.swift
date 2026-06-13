// WaterMinderTests.swift
// WaterMinder Pro 单元测试

import XCTest
@testable import WaterMinder

@MainActor
final class WaterMinderTests: XCTestCase {
    
    var recordStore: WaterRecordStore!
    
    override func setUp() {
        super.setUp()
        recordStore = WaterRecordStore()
        recordStore.items = []
        recordStore.save()
    }
    
    override func tearDown() {
        recordStore = nil
        super.tearDown()
    }
    
    // MARK: - Model Tests
    
    func testWaterRecordModelCreation() {
        // 测试创建 WaterRecordModel
        let record = WaterRecordModel(amount: 350, cupType: .medium, note: "测试记录")
        
        XCTAssertEqual(record.amount, 350)
        XCTAssertEqual(record.cupType, .medium)
        XCTAssertEqual(record.note, "测试记录")
        XCTAssertTrue(record.isCompleted)
        XCTAssertFalse(record.id.uuidString.isEmpty)
    }
    
    func testWaterRecordModelDefaultValues() {
        // 测试默认值
        let record = WaterRecordModel(amount: 200)
        
        XCTAssertEqual(record.cupType, .medium)
        XCTAssertNil(record.note)
        XCTAssertFalse(record.createdAt.timeIntervalSinceNow > 1) // 创建时间应该是现在
    }
    
    func testWaterRecordModelFormattedAmount() {
        // 测试格式化水量显示
        let record1 = WaterRecordModel(amount: 350)
        let record2 = WaterRecordModel(amount: 1200)
        let record3 = WaterRecordModel(amount: 50)
        
        XCTAssertEqual(record1.formattedAmount, "350ml")
        XCTAssertEqual(record2.formattedAmount, "1.2L") // 注意：实际格式化是 "1.2L"
        XCTAssertEqual(record3.formattedAmount, "50ml")
    }
    
    func testCupTypeDefaultAmounts() {
        // 测试杯型默认水量
        XCTAssertEqual(CupType.small.defaultAmount, 200)
        XCTAssertEqual(CupType.medium.defaultAmount, 350)
        XCTAssertEqual(CupType.large.defaultAmount, 500)
        XCTAssertEqual(CupType.bottle.defaultAmount, 750)
    }
    
    func testCupTypeIcons() {
        // 测试杯型图标
        XCTAssertEqual(CupType.small.icon, "cup.and.saucer.fill")
        XCTAssertEqual(CupType.medium.icon, "mug.fill")
        XCTAssertEqual(CupType.large.icon, "wineglass.fill")
        XCTAssertEqual(CupType.bottle.icon, "waterbottle.fill")
    }
    
    // MARK: - Store Tests
    
    func testRecordStoreAddRecord() {
        // 测试添加记录
        let record = recordStore.addRecord(amount: 350, cupType: .medium)
        
        XCTAssertEqual(recordStore.items.count, 1)
        XCTAssertEqual(recordStore.items.first?.amount, 350)
        XCTAssertEqual(recordStore.items.first?.cupType, .medium)
    }
    
    func testRecordStoreDeleteRecord() {
        // 测试删除记录
        let record1 = recordStore.addRecord(amount: 350)
        let record2 = recordStore.addRecord(amount: 500)
        
        XCTAssertEqual(recordStore.items.count, 2)
        
        recordStore.deleteRecord(record1)
        XCTAssertEqual(recordStore.items.count, 1)
        XCTAssertEqual(recordStore.items.first?.id, record2.id)
    }
    
    func testRecordStoreUpdateRecord() {
        // 测试更新记录
        let record = recordStore.addRecord(amount: 350, cupType: .medium)
        
        recordStore.updateRecord(record, amount: 500, cupType: .large, note: "更新测试")
        
        XCTAssertEqual(recordStore.items.first?.amount, 500)
        XCTAssertEqual(recordStore.items.first?.cupType, .large)
        XCTAssertEqual(recordStore.items.first?.note, "更新测试")
    }
    
    func testRecordStoreTodayRecords() {
        // 测试获取今日记录
        let record1 = recordStore.addRecord(amount: 350) // 今天
        _ = recordStore.addRecord(amount: 500) // 今天
        
        // 模拟昨天记录（需要修改 createdAt）
        var oldRecord = WaterRecordModel(amount: 200)
        oldRecord = WaterRecordModel(
            id: oldRecord.id,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            amount: oldRecord.amount,
            cupType: oldRecord.cupType,
            note: oldRecord.note
        )
        recordStore.items.append(oldRecord)
        
        XCTAssertEqual(recordStore.todayRecords.count, 2)
        XCTAssertTrue(recordStore.todayRecords.contains { $0.id == record1.id })
    }
    
    func testRecordStoreTodayTotalAmount() {
        // 测试今日总水量
        _ = recordStore.addRecord(amount: 350)
        _ = recordStore.addRecord(amount: 500)
        
        XCTAssertEqual(recordStore.todayTotalAmount, 850)
    }
    
    // MARK: - Statistics Tests
    
    func testRecordStoreTodayProgress() {
        // 测试今日进度计算
        recordStore.items = []
        _ = recordStore.addRecord(amount: 1000)
        
        // 默认目标是 2000ml，所以进度应该是 0.5
        let progress = recordStore.todayProgress
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
    
    func testRecordStoreThisWeekAverage() {
        // 测试本周平均水量
        let calendar = Calendar.current
        let today = Date()
        
        // 添加今天和昨天各一条记录
        _ = recordStore.addRecord(amount: 2000) // 今天
        
        var yesterdayRecord = WaterRecordModel(amount: 1500)
        yesterdayRecord = WaterRecordModel(
            id: yesterdayRecord.id,
            createdAt: calendar.date(byAdding: .day, value: -1, to: today)!,
            amount: yesterdayRecord.amount,
            cupType: yesterdayRecord.cupType,
            note: yesterdayRecord.note
        )
        recordStore.items.append(yesterdayRecord)
        
        // 平均应该是 (2000 + 1500) / 2 = 1750
        let average = recordStore.thisWeekAverage
        XCTAssertEqual(average, 1750)
    }
    
    // MARK: - Boundary Tests
    
    func testRecordStoreEmptyRecords() {
        // 测试空记录状态
        XCTAssertEqual(recordStore.items.count, 0)
        XCTAssertEqual(recordStore.todayTotalAmount, 0)
        XCTAssertEqual(recordStore.todayProgress, 0.0)
        XCTAssertEqual(recordStore.thisWeekAverage, 0)
    }
    
    func testWaterRecordModelZeroAmount() {
        // 测试零水量记录
        let record = WaterRecordModel(amount: 0)
        XCTAssertFalse(record.isCompleted)
        XCTAssertEqual(record.formattedAmount, "0ml")
    }
    
    func testCupTypeRawValues() {
        // 测试 CupType raw values
        XCTAssertEqual(CupType.small.rawValue, "小杯")
        XCTAssertEqual(CupType.medium.rawValue, "中杯")
        XCTAssertEqual(CupType.large.rawValue, "大杯")
        XCTAssertEqual(CupType.bottle.rawValue, "水瓶")
    }
    
    // MARK: - Performance Tests
    
    func testRecordStorePerformance() {
        // 性能测试：100 条记录下的计算性能
        for i in 0..<100 {
            _ = recordStore.addRecord(amount: 350)
        }
        
        measure {
            _ = recordStore.todayRecords
            _ = recordStore.todayTotalAmount
            _ = recordStore.todayProgress
        }
    }
    
    func testWaterRecordModelCreationPerformance() {
        // 性能测试：批量创建记录
        measure {
            for _ in 0..<1000 {
                _ = WaterRecordModel(amount: 350)
            }
        }
    }
}
