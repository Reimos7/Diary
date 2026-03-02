//
//  Double+TemperatureString.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation
import SwiftUI

fileprivate let formatter: MeasurementFormatter = {
    let f = MeasurementFormatter()
    f.numberFormatter.maximumFractionDigits = 0
    // .providedUnit: 로케일에 맞게 자동 변환 (섭씨↔화씨)
    f.unitOptions = .providedUnit
    return f
}()

// Double 값을 기온 값으로 바꾼 다음에 formatter를 써서 문자열로 바꿔서 리턴함
extension Double {
    var temperatureString: String {
        let temperature = Measurement<UnitTemperature>(value: self, unit: .celsius)
        // 로케일에 맞는 단위로 변환 (예: US → 화씨)
        let locale = Locale.current
        let converted: Measurement<UnitTemperature>
        if locale.usesMetricSystem {
            converted = temperature.converted(to: .celsius)
        } else {
            converted = temperature.converted(to: .fahrenheit)
        }
        let value = Int(converted.value.rounded())
        let unit = locale.usesMetricSystem ? "C" : "F"
        return "\(value)°\(unit)"
    }

    // WeatherView 메인 온도용 AttributedString
    // "°"와 단위(F/C) 사이의 간격(kern)만 좁혀서 자연스럽게 붙여줌
    var temperatureAttributedString: AttributedString {
        let locale = Locale.current
        let temperature = Measurement<UnitTemperature>(value: self, unit: .celsius)
        let converted = locale.usesMetricSystem
            ? temperature.converted(to: .celsius)
            : temperature.converted(to: .fahrenheit)
        let value = Int(converted.value.rounded())
        let unit = locale.usesMetricSystem ? "C" : "F"

        var number = AttributedString("\(value)")
        var degree = AttributedString("°")
        degree.kern = -4  // °와 F/C 사이 간격을 좁힘 (110pt 폰트 기준)
        var unitStr = AttributedString(unit)

        return number + degree + unitStr
    }

    // 현재 온도 숫자만 반환 (° 없이, 예: "56")
    // WeatherView에서 숫자(큰 폰트)와 단위(작은 폰트)를 분리 표시하기 위함
    var temperatureNumberString: String {
        let temperature = Measurement<UnitTemperature>(value: self, unit: .celsius)
        let locale = Locale.current
        let converted: Measurement<UnitTemperature>
        if locale.usesMetricSystem {
            converted = temperature.converted(to: .celsius)
        } else {
            converted = temperature.converted(to: .fahrenheit)
        }
        let value = Int(converted.value.rounded())
        return "\(value)"
    }

    // 현재 온도 단위 문자열 (예: "C" 또는 "F")
    // 로케일이 미터법이면 섭씨(C), 아니면 화씨(F)
    static var temperatureUnitString: String {
        return Locale.current.usesMetricSystem ? "C" : "F"
    }
    // 프리뷰에서는 랜덤 문자열을 추가하는걸 추가
    static var randomTempertureString: String {
        return Double.random(in: -10...30).temperatureString
    }
}
