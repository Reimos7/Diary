//
//  DiaryWidget.swift
//  DiaryWidget
//
//  Created by Reimos on 11/2/25.
//  2.0 디자인 통일: 크림 배경 + 2.0 색상 + 손그림 날씨 아이콘 + 파스텔 캘린더 + 연속 기록(스트릭).
//  (커스텀 폰트/사진은 위젯 타깃 폰트 추가·App Group 저장 마이그레이션 필요 → 후속 단계)
//

import WidgetKit
import SwiftUI
import SwiftData
import UIKit
import ImageIO

// MARK: - 2.0 색상 팔레트 (앱 AppColor와 동일 값, 위젯 타깃 자체 정의)

private extension Color {
    init(gdHex: String) {
        var int: UInt64 = 0
        Scanner(string: gdHex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
    static let gdBackground = Color(gdHex: "FAF7F1")   // 크림
    static let gdSurface = Color(gdHex: "FFFDF9")
    static let gdTextPrimary = Color(gdHex: "3A3632")
    static let gdTextSecondary = Color(gdHex: "9B948C")
    static let gdAccent = Color(gdHex: "8FA9C0")
    static let gdAccentSoft = Color(gdHex: "DCE5EE")
    static let gdDivider = Color(gdHex: "D9CFC0")
    static let gdSunday = Color(gdHex: "C98A8A")
    static let gdSaturday = Color(gdHex: "8FA9C0")
}

// MARK: - 커스텀 폰트 (App Group으로 받은 사용자 선택 폰트를 위젯 텍스트에 적용)
// 폰트 파일이 위젯 타깃에 없으면 .custom은 시스템 폰트로 자동 폴백된다(크래시 없음).

private struct GDFontNameKey: EnvironmentKey {
    static let defaultValue: String = "Cafe24DongdongOTF"
}
private extension EnvironmentValues {
    var gdFontName: String {
        get { self[GDFontNameKey.self] }
        set { self[GDFontNameKey.self] = newValue }
    }
}
private struct GDFontModifier: ViewModifier {
    @Environment(\.gdFontName) private var fontName
    let size: CGFloat
    func body(content: Content) -> some View {
        content.font(.custom(fontName, size: size))
    }
}
private extension View {
    func gdFont(_ size: CGFloat) -> some View { modifier(GDFontModifier(size: size)) }
}

// MARK: - 손그림 날씨 아이콘 (앱 WeatherIconView와 동일 매핑)

/// SF Symbol 이름 → 손그림 커스텀 에셋 이름(위젯 카탈로그에 복사됨). 매핑 없으면 nil.
private func gdWeatherAsset(for symbol: String?) -> String? {
    guard let s = symbol else { return nil }
    switch true {
    case s.contains("snow"), s.contains("snowflake"), s.contains("sleet"), s.contains("hail"):
        return "weather_snow"
    case s.contains("bolt"):
        return "weather_thunder"
    case s.contains("rain"), s.contains("drizzle"), s.contains("heavyrain"):
        return "weather_rain"
    case s.contains("wind"), s.contains("hurricane"), s.contains("tropicalstorm"), s.contains("tornado"):
        return "weather_wind"
    case s.contains("cloud.sun"):
        return "weather_cloudy_day"
    case s.contains("cloud.moon"):
        return "cloudy_night"
    case s.contains("fog"), s.contains("haze"), s.contains("smoke"), s.contains("dust"), s.contains("mist"):
        return "weather_cloudy"
    case s.contains("cloud"):
        return "weather_cloudy"
    case s.contains("moon"):
        return "clear_night"
    case s.contains("sun"):
        return "weather_clear_day"
    default:
        return nil
    }
}

/// 손그림 아이콘(있으면) 또는 SF Symbol 폴백.
private struct GDWeatherIcon: View {
    let symbol: String?
    var size: CGFloat = 28

    var body: some View {
        if let asset = gdWeatherAsset(for: symbol) {
            Image(asset).resizable().scaledToFit().frame(width: size, height: size)
        } else if let symbol {
            Image(systemName: symbol)
                .resizable().scaledToFit().frame(width: size, height: size)
                .foregroundStyle(Color.gdTextSecondary)
        }
    }
}

// MARK: - 사진(폴라로이드)

/// App Group 컨테이너에서 사진을 "다운샘플링"해서 로드(위젯 메모리 한도 대응).
private func gdLoadThumbnail(_ fileName: String?, maxPixel: CGFloat) -> UIImage? {
    guard let fileName,
          let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedModelContainer.appGroupIdentifier)
    else { return nil }
    let url = dir.appendingPathComponent(fileName)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel
    ]
    guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
    return UIImage(cgImage: cg)
}

/// List(기록) 화면과 동일한 찢은 종이(photo_frame) 프레임. 회전 없이 반듯하게.
private struct GDPolaroid: View {
    let image: UIImage
    /// 사진(프레임 안쪽) 크기.
    var size: CGFloat
    /// 프레임 테두리가 사진 가장자리를 덮도록 하는 여백.
    var inset: CGFloat = 9

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()
            .padding(inset)
            .overlay(
                // 찢은 종이 프레임을 위에 겹침 (가운데가 뚫려 사진이 비침) — List와 동일
                Image("photo_frame")
                    .resizable()
            )
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
    }
}

/// 연속 기록 배지.
private struct GDStreakBadge: View {
    let days: Int
    var body: some View {
        if days > 0 {
            HStack(spacing: 3) {
    
                Image("sesac")
                    .resizable().scaledToFit()
                    .frame(height: 16)
                Text("\(days)일째 기록 중")
                    .gdFont(12)
                    .foregroundStyle(Color.gdTextPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color.gdAccentSoft))
        }
    }
}

// MARK: - Timeline Provider

struct TodayDiaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayDiaryEntry {
        TodayDiaryEntry(date: Date(), todayDiary: nil, hasWrittenToday: false, diaryDates: [], streak: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayDiaryEntry) -> Void) {
        completion(TodayDiaryEntry(date: Date(), todayDiary: nil, hasWrittenToday: false, diaryDates: [], streak: 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayDiaryEntry>) -> Void) {
        let sharedDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
        let appLanguage = sharedDefaults?.string(forKey: "appLanguage") ?? "en"
        let fontName = sharedDefaults?.string(forKey: "selectedFont") ?? "Cafe24DongdongOTF"

        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!

        // 앱 잠금이 켜져 있으면 일기를 아예 읽지 않는다.
        // 화면에서 가리기만 해도 눈에는 안 보이지만, 위젯 프로세스 메모리에 본문과 사진을
        // 굳이 올릴 이유가 없다. 읽지 않는 것이 가장 확실한 차단이다.
        if SharedModelContainer.isAppLockEnabled {
            let lockedEntry = TodayDiaryEntry(
                date: currentDate,
                todayDiary: nil,
                hasWrittenToday: false,
                diaryDates: [],
                streak: 0,
                appLanguage: appLanguage,
                fontName: fontName,
                isLocked: true
            )
            completion(Timeline(entries: [lockedEntry], policy: .after(nextUpdate)))
            return
        }

        // 컨테이너/컨텍스트를 1회만 생성해 3개 조회에 공유 (위젯 시간·메모리 예산 절약)
        let modelContext = ModelContext(SharedModelContainer.create())
        let todayDiary = fetchTodayDiary(modelContext)
        let diaryDates = fetchThisMonthDiaryDates(modelContext)
        let streak = totalDiaryCount(modelContext)

        let entry = TodayDiaryEntry(
            date: currentDate,
            todayDiary: todayDiary,
            hasWrittenToday: todayDiary != nil,
            diaryDates: diaryDates,
            streak: streak,
            appLanguage: appLanguage,
            fontName: fontName
        )

        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func fetchTodayDiary(_ context: ModelContext) -> DiarySnapshot? {
        do {
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            let descriptor = FetchDescriptor<Diary>(
                predicate: #Predicate { $0.date >= startOfToday && $0.date < endOfToday },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            guard let diary = try context.fetch(descriptor).first else { return nil }
            return DiarySnapshot(content: diary.content, date: diary.date,
                                 weatherImage: diary.currentWeatherImage, imagePath: diary.imagePath?.first)
        } catch {
            return nil
        }
    }

    private func fetchThisMonthDiaryDates(_ context: ModelContext) -> Set<Date> {
        do {
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            let endOfMonthEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth)!
            let descriptor = FetchDescriptor<Diary>(
                predicate: #Predicate { $0.date >= startOfMonth && $0.date <= endOfMonthEnd }
            )
            return Set(try context.fetch(descriptor).map { calendar.startOfDay(for: $0.date) })
        } catch {
            return []
        }
    }

    /// 총 일기 개수 (홈 화면 "N일째 기록 중"과 동일한 기준).
    private func totalDiaryCount(_ context: ModelContext) -> Int {
        do {
            return try context.fetchCount(FetchDescriptor<Diary>())
        } catch {
            return 0
        }
    }
}

// MARK: - Timeline Entry

struct TodayDiaryEntry: TimelineEntry {
    let date: Date
    let todayDiary: DiarySnapshot?
    let hasWrittenToday: Bool
    let diaryDates: Set<Date>
    var streak: Int = 0
    var appLanguage: String = "en"
    var fontName: String = "Cafe24DongdongOTF"
    /// 앱 잠금이 켜져 있어 내용을 가려야 하는지.
    var isLocked: Bool = false
}

struct DiarySnapshot {
    let content: String
    let date: Date
    let weatherImage: String?
    let imagePath: String?
}

// MARK: - Widget Entry View

struct TodayDiaryWidgetEntryView: View {
    var entry: TodayDiaryEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Link(destination: URL(string: "diary://compose")!) {
            if entry.isLocked {
                // 잠금 중에는 크기와 무관하게 같은 화면을 보여준다.
                // 탭하면 앱이 열리고, 앱의 잠금 화면이 사용자를 맞이한다.
                LockedWidgetView()
            } else {
                switch family {
                case .systemSmall:  SmallWidgetView(entry: entry)
                case .systemMedium: MediumWidgetView(entry: entry)
                case .systemLarge:  LargeWidgetView(entry: entry)
                default:            SmallWidgetView(entry: entry)
                }
            }
        }
    }
}

// MARK: - 잠금 상태

/// 앱 잠금이 켜져 있을 때 위젯이 보여주는 화면.
///
/// 일기 본문·사진·캘린더 점 등 내용을 드러내는 요소는 하나도 넣지 않는다.
/// "쓴 날/안 쓴 날"처럼 사소해 보이는 정보도 잠금이 지키려는 사생활의 일부다.
struct LockedWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("sesac")
                .resizable()
                .scaledToFit()
                .frame(height: 34)

            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.58, green: 0.66, blue: 0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Small

struct SmallWidgetView: View {
    let entry: TodayDiaryEntry

    var body: some View {
        // 오늘 사진(있으면 다운샘플 로드)
        let photo = gdLoadThumbnail(entry.todayDiary?.imagePath, maxPixel: 340)

        if let photo {
            // 사진 있는 날: 실제 위젯 높이를 재서, 상하 레이블+여백을 뺀 나머지에 사진을 최대 크기로 배치
            GeometryReader { geo in
                // 날짜(~18) + 스트릭(~26) + 위아래 여백을 예약하고 나머지를 사진에 할당
                let reserved: CGFloat = 20
                let frameTotal = max(min(geo.size.width, geo.size.height - reserved), 60)
                VStack(spacing: 0) {
                    Text(entry.date, style: .date)
                        .gdFont(12)
                        .foregroundStyle(Color.gdTextSecondary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    GDPolaroid(image: photo, size: frameTotal - 18)   // 프레임 여백(inset*2=18) 제외
                    Spacer(minLength: 4)
                    if entry.streak > 0 {
                        GDStreakBadge(days: entry.streak)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        } else {
            // 텍스트 레이아웃 (좌측 정렬)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(entry.date, style: .date)
                        .gdFont(13)
                        .foregroundStyle(Color.gdTextSecondary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Spacer()
                    GDWeatherIcon(symbol: entry.todayDiary?.weatherImage, size: 28)
                }
                Spacer(minLength: 4)
                if entry.hasWrittenToday, let diary = entry.todayDiary {
                    Text(diary.content)
                        .gdFont(16)
                        .foregroundStyle(Color.gdTextPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("오늘의 순간을\n기록해보세요")
                        .gdFont(16)
                        .foregroundStyle(Color.gdTextPrimary)
                        .lineSpacing(2)
                }
                Spacer(minLength: 4)
                if entry.streak > 0 {
                    GDStreakBadge(days: entry.streak)
                }
            }
        }
    }
}

// MARK: - Medium

struct MediumWidgetView: View {
    let entry: TodayDiaryEntry

    var body: some View {
        // 오늘 사진(있으면 다운샘플 로드)
        let photo = gdLoadThumbnail(entry.todayDiary?.imagePath, maxPixel: 400)

        HStack(spacing: 14) {
            // 왼쪽: 사진 있으면 폴라로이드, 없으면 날짜 + 큰 날씨 아이콘
            if let photo {
                GDPolaroid(image: photo, size: 140)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.date, style: .date)
                        .gdFont(13)
                        .foregroundStyle(Color.gdTextSecondary)
                        .lineLimit(2).minimumScaleFactor(0.8)
                    Spacer()
                    GDWeatherIcon(symbol: entry.todayDiary?.weatherImage, size: 44)
                }
                .frame(width: 84, alignment: .leading)
            }

            Rectangle().fill(Color.gdDivider).frame(width: 1)

            // 오른쪽: (사진일 땐 날짜+날씨 / 아닐 땐 라벨) + 본문 + 스트릭
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    if photo != nil {
                        Text(entry.date, style: .date)
                            .gdFont(13)
                            .foregroundStyle(Color.gdTextSecondary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    } else {
                        Text(entry.hasWrittenToday ? "오늘의 일기" : "오늘의 일기를 남겨보세요")
                            .gdFont(13)
                            .foregroundStyle(Color.gdTextSecondary)
                    }
                    Spacer()
                    if photo != nil {
                        GDWeatherIcon(symbol: entry.todayDiary?.weatherImage, size: 26)
                    }
                }

                if entry.hasWrittenToday, let diary = entry.todayDiary {
                    Text(diary.content)
                        .gdFont(16)
                        .foregroundStyle(Color.gdTextPrimary)
                        .lineLimit(photo != nil ? 2 : 3)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("탭하여 기록을 시작하세요")
                        .gdFont(15)
                        .foregroundStyle(Color.gdTextPrimary)
                }

                Spacer(minLength: 2)

                if entry.streak > 0 {
                    GDStreakBadge(days: entry.streak)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)   // 우측 날짜/날씨·스트릭이 상하 가장자리에 붙지 않게 (좌측 사진엔 영향 없음)
        }
    }
}

// MARK: - Large (캘린더)

struct LargeWidgetView: View {
    let entry: TodayDiaryEntry

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(headerDateString)
                    .gdFont(19)
                    .foregroundStyle(Color.gdTextPrimary)
                Spacer()
                if entry.streak > 0 { GDStreakBadge(days: entry.streak) }
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            CalendarGridView(currentDate: entry.date, diaryDates: entry.diaryDates, appLanguage: entry.appLanguage)

            Spacer(minLength: 0)
        }
    }

    private var headerDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: entry.appLanguage)
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMMM")
        return formatter.string(from: entry.date)
    }
}

// MARK: - 캘린더 그리드

struct CalendarGridView: View {
    let currentDate: Date
    let diaryDates: Set<Date>
    var appLanguage: String = "en"

    private let calendar = Calendar.current
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: appLanguage)
        return formatter.veryShortWeekdaySymbols
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .gdFont(12)
                        .foregroundStyle(weekdayColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 3) {
                ForEach(0..<6, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            let dateIndex = weekIndex * 7 + dayIndex
                            if dateIndex < daysInMonth.count {
                                dayCell(for: daysInMonth[dateIndex], weekday: dayIndex)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(for dateInfo: DateInfo, weekday: Int) -> some View {
        if dateInfo.isCurrentMonth {
            VStack(spacing: 3) {
                Text("\(dateInfo.day)")
                    .gdFont(13)
                    .foregroundStyle(dateForegroundColor(for: dateInfo, weekday: weekday))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().stroke(Color.gdAccent, lineWidth: isToday(dateInfo.date) ? 1.5 : 0)
                    )
                // 일기 있는 날: 부드러운 파스텔 점
                Circle()
                    .fill(hasDiary(on: dateInfo.date) ? Color.gdAccent : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
        } else {
            Color.clear.frame(maxWidth: .infinity).frame(height: 40)
        }
    }

    private var daysInMonth: [DateInfo] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = firstWeekday - 1
        var dates: [DateInfo] = []
        for _ in 0..<offsetDays {
            dates.append(DateInfo(date: Date.distantPast, day: 0, isCurrentMonth: false))
        }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(DateInfo(date: date, day: day, isCurrentMonth: true))
            }
        }
        return dates
    }

    private func isToday(_ date: Date) -> Bool { calendar.isDateInToday(date) }
    private func hasDiary(on date: Date) -> Bool { diaryDates.contains(calendar.startOfDay(for: date)) }

    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return .gdSunday
        case 6: return .gdSaturday
        default: return .gdTextSecondary
        }
    }

    private func dateForegroundColor(for dateInfo: DateInfo, weekday: Int) -> Color {
        switch weekday {
        case 0: return .gdSunday
        case 6: return .gdSaturday
        default: return .gdTextPrimary
        }
    }
}

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
                .environment(\.locale, Locale(identifier: entry.appLanguage))
                .environment(\.gdFontName, entry.fontName)   // 사용자 선택 폰트 적용
                .containerBackground(for: .widget) {
                    Color.gdBackground   // 크림 배경 (2.0 통일)
                }
        }
        .configurationDisplayName(Text("오늘의 일기"))
        .description(Text("오늘 작성한 일기를 확인하세요"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DiaryWidget()
} timeline: {
    TodayDiaryEntry(date: .now, todayDiary: nil, hasWrittenToday: false, diaryDates: [], streak: 0)
    TodayDiaryEntry(date: .now,
                    todayDiary: DiarySnapshot(content: "오랜만에 친구들과 바다를 보러 다녀왔다.", date: .now, weatherImage: "sun.max.fill", imagePath: nil),
                    hasWrittenToday: true, diaryDates: sampleDiaryDates(), streak: 3)
}

#Preview(as: .systemMedium) {
    DiaryWidget()
} timeline: {
    TodayDiaryEntry(date: .now,
                    todayDiary: DiarySnapshot(content: "오랜만에 친구들과 바다를 보러 다녀왔다. 날씨가 참 좋았다.", date: .now, weatherImage: "cloud.sun.fill", imagePath: nil),
                    hasWrittenToday: true, diaryDates: sampleDiaryDates(), streak: 5)
}

#Preview(as: .systemLarge) {
    DiaryWidget()
} timeline: {
    TodayDiaryEntry(date: .now, todayDiary: nil, hasWrittenToday: false, diaryDates: sampleDiaryDates(), streak: 5)
}

private func sampleDiaryDates() -> Set<Date> {
    let calendar = Calendar.current
    let today = Date()
    var dates: Set<Date> = []
    for offset in [-5, -3, -1, 0] {
        if let d = calendar.date(byAdding: .day, value: offset, to: today) {
            dates.insert(calendar.startOfDay(for: d))
        }
    }
    return dates
}
