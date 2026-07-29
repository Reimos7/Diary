//
//  CalendarView.swift
//  Diary
//
//  캘린더 탭 화면. FSCalendar 대신 SwiftUI로 직접 구현 (스티치 디자인).
//  - 헤더: 좌우 화살표로 월 이동 + 월 타이틀
//  - 날짜 그리드: 일기 있는 날 = 파스텔 원, 오늘 = 테두리 원, 미래 = 비활성
//  - Memories: 최근 사진 있는 일기 썸네일
//
//  [메모]
//  - 파스텔 색은 날짜 기반으로 고정(결정적)해 화면 갱신 시 깜빡이지 않게 함.
//  - 날짜 선택 시 그 날짜 작성 화면으로 이동(기존 동작 유지).
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var manager: SwiftDataManager
    @EnvironmentObject var fontManager: FontManager

    // 현재 화면에 표시 중인 달
    @State private var displayedMonth: Date = Date()
    // 날짜 선택 → 작성 이동
    @State private var selectedDate: Date = Date()
    @State private var navigateToCompose = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    header
                    weekdayRow
                    dateGrid
                    memoriesSection
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToCompose) {
                CalendarComposeView(selectedDate: $selectedDate)
            }
        }
    }

    // MARK: - 헤더 (월 이동 화살표 + 타이틀)

    private var header: some View {
        HStack {
            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
            Text(monthTitle)
                .customFont(size: 22)
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    // MARK: - 요일 행

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                Text(weekdaySymbols[i])
                    .customFont(size: 13)
                    .foregroundStyle(weekdayHeaderColor(i))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 날짜 그리드

    private var dateGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(monthCells.indices, id: \.self) { index in
                dayCell(monthCells[index])
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date {
            let day = calendar.component(.day, from: date)
            let isToday = calendar.isDateInToday(date)
            let hasDiary = manager.hasDiaryentry(for: date)
            let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())

            Button {
                selectedDate = date
                navigateToCompose = true
            } label: {
                ZStack {
                    // 일기 있는 날 = 파스텔 원
                    if hasDiary {
                        Circle()
                            .fill(pastelColor(for: date))
                            .frame(width: 38, height: 38)
                    }
                    // 오늘 = 테두리 원
                    if isToday {
                        Circle()
                            .stroke(AppColor.textPrimary, lineWidth: 1)
                            .frame(width: 38, height: 38)
                    }
                    Text("\(day)")
                        .customFont(size: 16)
                        .foregroundStyle(dayColor(date, isFuture: isFuture))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .disabled(isFuture)
        } else {
            Color.clear.frame(height: 44)
        }
    }

    // MARK: - Memories (최근 사진 있는 일기 썸네일)

    private var memoriesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Memories")
                .customFont(size: 14)
                .foregroundStyle(AppColor.textSecondary)

            // 항상 4칸 표시: 사진 있으면 폴라로이드, 없으면 빈 틀 (심심하지 않게)
            HStack(spacing: AppSpacing.md) {
                ForEach(0..<4, id: \.self) { index in
                    memorySlot(index: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AppSpacing.md)
    }

    @ViewBuilder
    private func memorySlot(index: Int) -> some View {
        let mems = memories
        if index < mems.count,
           let fileName = mems[index].imagePath?.first,
           let image = FileManagerSet.loadImageFromFileManager(fileName: fileName) {
            // 사진 있는 슬롯 → 종이 프레임 + 탭 시 상세 이동
            NavigationLink {
                DetailView(data: mems[index])
            } label: {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipped()
                    .polaroid()
            }
        } else {
            // 빈 슬롯 → 투명한 종이 프레임만 (안쪽은 배경색이 비쳐 자연스럽게 빔)
            Color.clear
                .frame(width: 58, height: 58)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(AppColor.textSecondary.opacity(0.3))
                )
                .polaroid()
        }
    }

    // MARK: - 데이터/헬퍼

    /// 표시 중인 달의 셀 배열(앞쪽 빈칸 nil + 날짜들).
    private var monthCells: [Date?] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) // 1=일 ... 7=토
        var cells: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        for day in 0..<range.count {
            cells.append(calendar.date(byAdding: .day, value: day, to: firstOfMonth))
        }
        return cells
    }

    /// 최근 사진이 있는 일기 (최대 4개).
    private var memories: [Diary] {
        manager.diaryEntries
            .filter { !($0.imagePath?.isEmpty ?? true) }
            .prefix(4)
            .map { $0 }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = appLocale
        f.setLocalizedDateFormatFromTemplate("yyyy MMMM")
        return f.string(from: displayedMonth)
    }

    /// 요일 심볼 (일~토), 앱 언어에 맞게.
    private var weekdaySymbols: [String] {
        let f = DateFormatter()
        f.locale = appLocale
        return f.veryShortStandaloneWeekdaySymbols ?? ["일","월","화","수","목","금","토"]
    }

    private func weekdayHeaderColor(_ index: Int) -> Color {
        switch index {
        case 0: return AppColor.sunday
        case 6: return AppColor.saturday
        default: return AppColor.textSecondary
        }
    }

    private func dayColor(_ date: Date, isFuture: Bool) -> Color {
        if isFuture { return AppColor.textSecondary.opacity(0.4) }
        let weekday = calendar.component(.weekday, from: date)
        switch weekday {
        case 1: return AppColor.sunday
        case 7: return AppColor.saturday
        default: return AppColor.textPrimary
        }
    }

    /// 날짜 기반 결정적 파스텔 색 (같은 날은 항상 같은 색, 날짜마다 다르게).
    private func pastelColor(for date: Date) -> Color {
        let dayNumber = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return AppColor.calendarPastels[dayNumber % AppColor.calendarPastels.count]
    }

    private func changeMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = d
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(SwiftDataManager())
        .environmentObject(FontManager())
}
