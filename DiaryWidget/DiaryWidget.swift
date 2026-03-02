//
//  DiaryWidget.swift
//  DiaryWidget
//
//  Created by Reimos on 11/2/25.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider
// 위젯에 표시할 데이터를 제공하는 Provider
struct TodayDiaryProvider: TimelineProvider {
    // Placeholder: 위젯 갤러리에서 보여지는 샘플 데이터
    func placeholder(in context: Context) -> TodayDiaryEntry {
        TodayDiaryEntry(
            date: Date(),
            todayDiary: nil,
            hasWrittenToday: false,
            diaryDates: []
        )
    }

    // Snapshot: 위젯 추가 시 미리보기
    func getSnapshot(in context: Context, completion: @escaping (TodayDiaryEntry) -> Void) {
        let entry = TodayDiaryEntry(
            date: Date(),
            todayDiary: nil,
            hasWrittenToday: false,
            diaryDates: []
        )
        completion(entry)
    }

    // Timeline: 실제 위젯 데이터 제공
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayDiaryEntry>) -> Void) {
        // App Group에서 사용자가 앱에서 선택한 언어를 읽어서 위젯에도 적용
        // 위젯은 앱과 별도 프로세스이므로 App Group UserDefaults를 통해 언어를 공유받음
        let sharedDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
        // 미지원 언어 사용자는 영어로 fallback (앱과 동일한 정책)
        let appLanguage = sharedDefaults?.string(forKey: "appLanguage") ?? "en"

        // 현재 날짜
        let currentDate = Date()

        // SwiftData에서 오늘의 일기 가져오기
        let todayDiary = fetchTodayDiary()

        // 이번 달의 모든 일기 날짜 가져오기
        let diaryDates = fetchThisMonthDiaryDates()

        // Entry 생성 (언어 코드도 함께 전달)
        let entry = TodayDiaryEntry(
            date: currentDate,
            todayDiary: todayDiary,
            hasWrittenToday: todayDiary != nil,
            diaryDates: diaryDates,
            appLanguage: appLanguage
        )

        // Timeline 정책 설정
        // 1시간마다 갱신 (배터리 효율 고려)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // SwiftData에서 오늘의 일기를 가져오는 함수
    private func fetchTodayDiary() -> DiarySnapshot? {
        do {
            // 공유 ModelContainer 사용
            let container = SharedModelContainer.create()
            let context = ModelContext(container)

            // 오늘 00:00:00부터 23:59:59까지의 범위
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            // FetchDescriptor로 오늘의 일기 검색
            let descriptor = FetchDescriptor<Diary>(
                predicate: #Predicate { diary in
                    diary.date >= startOfToday && diary.date < endOfToday
                },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )

            let diaries = try context.fetch(descriptor)

            // 가장 최근 일기 반환 (오늘 여러 개 작성했을 경우 최신 것)
            guard let diary = diaries.first else { return nil }

            // Diary -> DiarySnapshot 변환
            return DiarySnapshot(
                content: diary.content,
                date: diary.date,
                weatherImage: diary.currentWeatherImage,
                imagePath: diary.imagePath?.first // 첫 번째 이미지만
            )

        } catch {
            print("위젯에서 일기 가져오기 실패: \(error)")
            return nil
        }
    }

    // 이번 달의 모든 일기 날짜를 가져오는 함수 (캘린더용)
    private func fetchThisMonthDiaryDates() -> Set<Date> {
        do {
            let container = SharedModelContainer.create()
            let context = ModelContext(container)

            let calendar = Calendar.current
            let now = Date()

            // 이번 달의 시작일과 종료일
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            let endOfMonthEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth)!

            // 이번 달의 모든 일기 검색
            let descriptor = FetchDescriptor<Diary>(
                predicate: #Predicate { diary in
                    diary.date >= startOfMonth && diary.date <= endOfMonthEnd
                }
            )

            let diaries = try context.fetch(descriptor)

            // 날짜만 추출 (시간 정보 제거하여 날짜별로 그룹화)
            let dates = Set(diaries.map { calendar.startOfDay(for: $0.date) })

            return dates

        } catch {
            print("위젯에서 이번 달 일기 날짜 가져오기 실패: \(error)")
            return []
        }
    }
}

// MARK: - Timeline Entry
// 위젯에 표시될 단일 시점의 데이터
struct TodayDiaryEntry: TimelineEntry {
    let date: Date // 위젯이 업데이트되는 시간
    let todayDiary: DiarySnapshot? // 오늘의 일기 (없을 수 있음)
    let hasWrittenToday: Bool // 오늘 작성 여부
    let diaryDates: Set<Date> // 이번 달에 일기가 작성된 날짜들 (캘린더용)
    var appLanguage: String = "en" // 앱에서 선택한 언어 (위젯에 locale 적용용, 미지원 언어는 영어 fallback)
}

// MARK: - Diary Snapshot (위젯용 가벼운 모델)
// SwiftData의 Diary 모델을 위젯에서 사용하기 위한 Snapshot
// @Model 객체를 위젯에서 직접 사용하면 메모리 문제 발생 가능
struct DiarySnapshot {
    let content: String
    let date: Date
    let weatherImage: String?
    let imagePath: String? // 파일명
}

// MARK: - Widget Entry View
// 위젯 UI를 그리는 뷰
struct TodayDiaryWidgetEntryView: View {
    var entry: TodayDiaryEntry
    @Environment(\.widgetFamily) var family // Small, Medium, Large 구분

    var body: some View {
        // 위젯 탭 시 일기 작성 화면으로 이동하는 딥링크
        Link(destination: URL(string: "diary://compose")!) {
            widgetContent
        }
    }

    @ViewBuilder
    private var widgetContent: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View (Small 크기)
struct SmallWidgetView: View {
    let entry: TodayDiaryEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // 배경색 - 굿디 앱 스타일 (다크모드 대응)
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                // 일기 작성 여부
                if entry.hasWrittenToday, let diary = entry.todayDiary {
                    // 작성함 - 날짜와 시간 표시
                    VStack(alignment: .leading, spacing: 4) {
                        Text(diary.date, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(diary.date, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 일기 내용 미리보기
                    Text(diary.content)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // 하단: 날씨 아이콘
                    HStack {
                        Spacer()
                        if let weatherImage = diary.weatherImage {
                            Image(systemName: weatherImage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // 작성 안 함
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text("오늘의 순간을\n기록해보세요")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)

                    Spacer()
                }
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget View (Medium 크기)
struct MediumWidgetView: View {
    let entry: TodayDiaryEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // 배경색 - 굿디 앱 스타일 (다크모드 대응)
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            if entry.hasWrittenToday, let diary = entry.todayDiary {
                // 일기를 작성한 경우
                HStack(alignment: .top, spacing: 16) {
                    // 왼쪽: 날짜 & 시간 & 날씨
                    VStack(alignment: .leading, spacing: 8) {
                        // 날짜
                        VStack(alignment: .leading, spacing: 2) {
                            Text(diary.date, style: .date)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text(diary.date, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // 날씨 아이콘
                        if let weatherImage = diary.weatherImage {
                            VStack(spacing: 4) {
                                Image(systemName: weatherImage)
                                    .font(.title2)
                                    .foregroundColor(.primary)

                                Text("날씨")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(width: 70)

                    // 오른쪽: 일기 내용 미리보기
                    VStack(alignment: .leading, spacing: 8) {
                        Text("오늘의 일기")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        // 일기 내용 (최대 3줄)
                        Text(diary.content)
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()

            } else {
                // 일기를 작성하지 않은 경우
                VStack(alignment: .leading, spacing: 12) {
                    // 상단: 날짜
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Spacer()

                    // 중앙: 메시지
                    VStack(alignment: .leading, spacing: 8) {
                        Text("오늘의 일기를 작성하세요")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("탭하여 일기 쓰기 시작")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}

// MARK: - Large Widget View (Large 크기) - 캘린더 뷰
struct LargeWidgetView: View {
    let entry: TodayDiaryEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // 배경색 - 굿디 앱 스타일 (다크모드 대응)
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // 상단: 현재 년/월 표시
                HStack {
                    Text(headerDateString)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // 캘린더 그리드
                CalendarGridView(currentDate: entry.date, diaryDates: entry.diaryDates, appLanguage: entry.appLanguage)

                Spacer(minLength: 0)
            }
        }
    }

    // 로케일에 맞게 년/월 표시 (한: "2026년 2월" / 영: "February 2026" / 일: "2026年2月")
    private var headerDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: entry.appLanguage)
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMMM")
        return formatter.string(from: entry.date)
    }
}

// MARK: - 캘린더 그리드 뷰
struct CalendarGridView: View {
    let currentDate: Date
    let diaryDates: Set<Date>
    var appLanguage: String = "en"
    @Environment(\.colorScheme) var colorScheme

    private let calendar = Calendar.current
    // 앱 언어 설정에 맞게 요일 표시 (한: 일,월,화.. / 영: S,M,T.. / 일: 日,月,火..)
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: appLanguage)
        return formatter.veryShortWeekdaySymbols
    }

    var body: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(weekdayColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // 날짜 그리드 (6주 x 7일)
            VStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            let dateIndex = weekIndex * 7 + dayIndex
                            if dateIndex < daysInMonth.count {
                                dayCell(for: daysInMonth[dateIndex], weekday: dayIndex)
                            } else {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // 각 날짜 셀
    @ViewBuilder
    private func dayCell(for dateInfo: DateInfo, weekday: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(dateInfo.day)")
                .font(.caption)
                .fontWeight(isToday(dateInfo.date) ? .bold : .regular)
                .foregroundColor(dateForegroundColor(for: dateInfo, weekday: weekday))

            // 일기 작성된 날짜는 빨간 점 표시
            if hasDiary(on: dateInfo.date) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear
                    .frame(width: 4, height: 4)
            }

            // "오늘" 텍스트
            if isToday(dateInfo.date) {
                Text("오늘")
                    .font(.system(size: 8))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 45)
    }

    // 이번 달의 날짜 배열 생성
    private var daysInMonth: [DateInfo] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        // 첫 번째 날의 요일 (일요일 = 1)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = firstWeekday - 1 // 0부터 시작

        var dates: [DateInfo] = []

        // 이전 달 날짜로 패딩
        for _ in 0..<offsetDays {
            dates.append(DateInfo(date: Date.distantPast, day: 0, isCurrentMonth: false))
        }

        // 이번 달 날짜
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(DateInfo(date: date, day: day, isCurrentMonth: true))
            }
        }

        return dates
    }

    // 오늘 날짜인지 확인
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    // 일기가 작성된 날짜인지 확인
    private func hasDiary(on date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return diaryDates.contains(startOfDay)
    }

    // 요일별 색상 (일요일: 빨강, 토요일: 파랑)
    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return .red
        case 6: return .blue
        default: return .primary
        }
    }

    // 날짜 텍스트 색상
    private func dateForegroundColor(for dateInfo: DateInfo, weekday: Int) -> Color {
        if !dateInfo.isCurrentMonth {
            return .gray.opacity(0.3)
        }

        switch weekday {
        case 0: return .red
        case 6: return .blue
        default: return .primary
        }
    }
}

// MARK: - 날짜 정보 모델
struct DateInfo {
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
}

// MARK: - Widget Configuration
struct DiaryWidget: Widget {
    let kind: String = "TodayDiaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayDiaryProvider()) { entry in
            TodayDiaryWidgetEntryView(entry: entry)
                // 앱에서 선택한 언어를 위젯에도 적용 (앱의 DiaryApp과 동일한 방식)
                .environment(\.locale, Locale(identifier: entry.appLanguage))
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        // LocalizedStringKey로 전달 -> String Catalog에서 번역 자동 적용
        .configurationDisplayName(Text("오늘의 일기"))
        .description(Text("오늘 작성한 일기를 확인하세요"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    DiaryWidget()
} timeline: {
    // 작성 안 한 경우
    TodayDiaryEntry(date: .now, todayDiary: nil, hasWrittenToday: false, diaryDates: [])

    // 작성한 경우
    TodayDiaryEntry(
        date: .now,
        todayDiary: DiarySnapshot(
            content: "오늘은 정말 좋은 하루였다! 날씨도 좋고 기분도 좋았어요.",
            date: .now,
            weatherImage: "sun.max.fill",
            imagePath: nil
        ),
        hasWrittenToday: true,
        diaryDates: sampleDiaryDates()
    )
}

#Preview(as: .systemMedium) {
    DiaryWidget()
} timeline: {
    TodayDiaryEntry(
        date: .now,
        todayDiary: DiarySnapshot(
            content: "오늘은 정말 좋은 하루였다! 날씨도 좋고 기분도 좋았어요.",
            date: .now,
            weatherImage: "sun.max.fill",
            imagePath: nil
        ),
        hasWrittenToday: true,
        diaryDates: sampleDiaryDates()
    )
}

#Preview(as: .systemLarge) {
    DiaryWidget()
} timeline: {
    TodayDiaryEntry(
        date: .now,
        todayDiary: nil,
        hasWrittenToday: false,
        diaryDates: sampleDiaryDates()
    )
}

// MARK: - Preview 샘플 데이터
private func sampleDiaryDates() -> Set<Date> {
    let calendar = Calendar.current
    let today = Date()
    var dates: Set<Date> = []

    // 이번 달의 몇 개 날짜에 일기가 있다고 가정 (Preview용 샘플)
    if let date1 = calendar.date(byAdding: .day, value: -5, to: today) {
        dates.insert(calendar.startOfDay(for: date1))
    }
    if let date2 = calendar.date(byAdding: .day, value: -3, to: today) {
        dates.insert(calendar.startOfDay(for: date2))
    }
    dates.insert(calendar.startOfDay(for: today))

    return dates
}
