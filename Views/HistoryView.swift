// HistoryView.swift
// 记录页面 - 显示历史喝水记录

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var recordStore: WaterRecordStore
    @EnvironmentObject var appState: AppState
    
    @State private var selectedDate = Date()
    @State private var showingEditRecord = false
    @State private var editingRecord: WaterRecordModel?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日期选择器
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                
                // 当日统计
                DaySummaryView(date: selectedDate)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // 记录列表
                List {
                    ForEach(recordsForSelectedDate) { record in
                        RecordDetailRowView(record: record)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteRecord(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                
                                Button {
                                    editingRecord = record
                                    showingEditRecord = true
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("喝水记录")
            .background(Color(.systemBackground))
            .sheet(isPresented: $showingEditRecord) {
                if let record = editingRecord {
                    EditRecordView(record: record)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var recordsForSelectedDate: [WaterRecordModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return recordStore.items.filter { record in
            record.createdAt >= startOfDay && record.createdAt < endOfDay
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Private Methods
    
    private func deleteRecord(_ record: WaterRecordModel) {
        recordStore.deleteRecord(record)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Day Summary View
struct DaySummaryView: View {
    let date: Date
    @EnvironmentObject var recordStore: WaterRecordStore
    
    private var records: [WaterRecordModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return recordStore.items.filter { record in
            record.createdAt >= startOfDay && record.createdAt < endOfDay
        }
    }
    
    private var totalAmount: Int {
        records.reduce(0) { $0 + $1.amount }
    }
    
    private var averageAmount: Int {
        guard !records.isEmpty else { return 0 }
        return totalAmount / records.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(totalAmount)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text("总摄入量(ml)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(records.count)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text("记录次数")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(averageAmount)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text("平均(ml)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Record Detail Row View
struct RecordDetailRowView: View {
    let record: WaterRecordModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.cupType.icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.cupType.rawValue)
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                    Text(record.formattedAmount)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                }
                
                HStack {
                    Text(record.timeString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let note = record.note {
                        Text("• \(note)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Edit Record View
struct EditRecordView: View {
    let record: WaterRecordModel
    @EnvironmentObject var recordStore: WaterRecordStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var amount: String
    @State private var selectedCupType: CupType
    @State private var note: String
    
    init(record: WaterRecordModel) {
        self.record = record
        self._amount = State(initialValue: "\(record.amount)")
        self._selectedCupType = State(initialValue: record.cupType)
        self._note = State(initialValue: record.note ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("喝水信息")) {
                    TextField("水量(ml)", text: $amount)
                        .keyboardType(.numberPad)
                    
                    Picker("杯型", selection: $selectedCupType) {
                        ForEach(CupType.allCases, id: \.self) { cupType in
                            Text(cupType.description).tag(cupType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("备注")) {
                    TextField("可选备注", text: $note)
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveRecord()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        guard let amountInt = Int(amount), amountInt > 0 else { return false }
        return true
    }
    
    private func saveRecord() {
        guard let amountInt = Int(amount) else { return }
        
        recordStore.updateRecord(record, amount: amountInt, cupType: selectedCupType, note: note.isEmpty ? nil : note)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environmentObject(WaterRecordStore())
            .environmentObject(AppState.shared)
    }
}
