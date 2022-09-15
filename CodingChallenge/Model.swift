// Shift.swift

import Foundation

struct DayShift: Codable, Identifiable{

  var id: String {
    return date
  }

  var date: String
  var dateAsDate: Date? {

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(abbreviation: "UTC")

    print("Date: \(date)")
    print("Formatted date \(formatter.date(from:date)!.description)")
    return formatter.date(from: date)
  }

  var shifts: [Shift]
}

struct Shift: Codable, Identifiable {

  func convertToTimeOnlyString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }

  var id: UInt {
    return shift_id
  }
  var shift_id: UInt
  var start_time: String
  var start_timeDate: Date? {
    return ISO8601DateFormatter().date(from: start_time)
  }
  var start_timeOnly: String {
    guard let start_timeDate = start_timeDate else {
      return ""
    }
    return convertToTimeOnlyString(from: start_timeDate)
  }
  var end_time: String
  var end_timeDate: Date? {
    return ISO8601DateFormatter().date(from: end_time)
  }
  var end_timeOnly: String {
    guard let end_timeDate = end_timeDate else {
      return ""
    }
    return convertToTimeOnlyString(from: end_timeDate)
  }
  var premium_rate: Bool
  var covid: Bool
  var within_distance: UInt?
  var facility_type: FacilityType
  var skill: Skill
  var localized_specialty: LocalizedSpeciality
}

struct FacilityType: Codable {

  var id: UInt
  var name: String
  var color: String
}

struct Skill: Codable {

  var id: UInt
  var name: String
  var color: String
}

struct LocalizedSpeciality: Codable {

  var id: UInt
  var name: String
  var abbreviation: String
  var specialty: Speciality
}

struct Speciality: Codable {

  var id: Int
  var name: String
  var abbreviation: String
  var color: String
}

class ShiftStore: Codable, ObservableObject {

  init(date: Date, shifts: [Shift]) {
    self.date = date
    self.shifts = shifts
  }

  var date: Date
  var shifts: [Shift]
}
