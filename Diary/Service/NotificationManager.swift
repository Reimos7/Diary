//
//  NotificationManager.swift
//  Diary
//
//  Created by Reimos on 3/30/25.
//

import SwiftUI
import UserNotifications

// 오늘 일기를 작성하지 않은 경우 오후 11시에 푸시 알림
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func checkScheduleNotification(entries: [Diary]) {
        
        // startOfDay(for:)는 날짜의 시각을 00:00으로 맞추어 비교할 수 있음
        let today = Calendar.current.startOfDay(for: Date())
        // 오늘 작성한 일기 존재 유무 판단
        let hasDiaryToday = entries.contains {
            // inSameDayAs:를 사용하면 같은 날짜인지 쉽게 판단
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        // 오늘 일기 없을때만 실행
        if !hasDiaryToday {
            print("오늘 작성된 일기가 없으니 scheduleNotification 실행")
            scheduleNotification()
        } else {
            print("오늘 작성된 일기가 있어요")
            // 일기가 있으면 알림 필요 없으니까 제거
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["diaryReminder"])
        }
    }
    
    // 사용자에게 알림 권한 요청을 보냄
    func requestAutorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Request Authorization Error: \(error.localizedDescription)")
            } else if granted {
                print("permission granted")
            } else {
                print("permission denied")
            }
        }
    }
    
    // 알림 객체를 만들고 내용을 작성, 알림이 언제 울리게 할지 정한다
    // 오늘 작성한 일기가 없으면 매일 오후 11시에 알림 발송
    func scheduleNotification() {
        // 알림 설정이 꺼져 있으면 아무 작업도 하지 않음
        if !UserDefaults.standard.bool(forKey: "isPushNotificationEnabled") {
            print("알림 설정이 꺼져 있어 알림을 예약하지 않습니다")
            return
        }
        
        // 중복 예약 방지
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["diaryReminder"])
        
        let today = DateFormatter.dateScheduleNotificationFormatter.string(from: Date())
        let content = UNMutableNotificationContent()
        
        content.title = "🗓️ \(today) (오늘) 일기가 없어요"
        //content.subtitle = "subtitle"
        content.body = " ✍️ 하루를 기록해 보는 건 어때요?"
        content.sound = UNNotificationSound.default
        
        // 알림 날짜및 시간 설정
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        dateComponents.hour = 23  // 오후 11시
        //dateComponents.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "diaryReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("error : \(error.localizedDescription)")
            } else {
                print("notification scheduled")
            }
            
        }
        
    }
    
    // 푸시 알림 취소 메서드
    func cancelPushNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("푸시 알림 취소")
    }
    
    
    // 해당 함수는 willPresent 과 didReceive 에 따라 작동하는 함수다. 알림이 울릴 때와, 알림을 받았을 때 어떤 작업을 처리할지 작성하면 된다
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list , .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
