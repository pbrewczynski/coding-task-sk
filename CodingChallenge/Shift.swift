// Shift.swift

import Foundation

struct Shift: Codable, Identifiable {

  enum CodingKeys: String, CodingKey {
    case id = "shift_id"
    case start_time
    case end_time
    case premium_rate
    case covid
    case within_distance
    case facility_type
  }

  var id: UInt
  var start_time: String
  var end_time: String
  var premium_rate: Bool
  var covid: Bool
  var within_distance: UInt?
  var facility_type: FacilityType
}

struct FacilityType: Codable {
  var id: Int
  var name: String
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
