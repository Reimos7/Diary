//
//  Double+TemperatureString.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation

fileprivate let formatter: MeasurementFormatter = {
    let f = MeasurementFormatter()
    f.numberFormatter.maximumFractionDigits = 0
    // 온도에 15oF 이런거 있으면 뒤에 F빼기
    f.unitOptions = .temperatureWithoutUnit
    return f
}()

// Double 값을 기온 값으로 바꾼 다음에 fommater을 써서  문자열로 바꿔서 리턴함
extension Double {
    var temperatureString: String {
        let temperature = Measurement<UnitTemperature>(value: self, unit: .celsius)
        return formatter.string(from: temperature)
    }
    // 프리뷰에서는 랜덤 문자열을 추가하는걸 추가
    static var randomTempertureString: String {
        return Double.random(in: -10...30).temperatureString
    }
}
