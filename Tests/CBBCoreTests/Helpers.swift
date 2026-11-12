import Foundation
@testable import CBBCore

func fixture(_ name: String) -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
    return try! Data(contentsOf: url)
}

/// A wall-clock time in America/New_York, written "yyyy-MM-dd HH:mm".
func et(_ s: String) -> Date {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: "America/New_York")
    f.dateFormat = "yyyy-MM-dd HH:mm"
    return f.date(from: s)!
}
