// CodingChallengeApp.swift

import SwiftUI

@main
struct CodingChallengeApp: App {

    var body: some Scene {

        WindowGroup {
          ShiftsView(shiftsStore: ShiftStore(date: Date.distantPast, shifts: [Shift(shift_id:0, start_time: "", end_time: "", premium_rate: false, covid: false, within_distance: 20, facility_type: FacilityType(id: 0, name: "name", color: "#121212"), skill: Skill(id: 0, name: "", color: ""), localized_specialty: LocalizedSpeciality(id: 0, name: "", abbreviation: "", specialty: Speciality(id: 0, name: "", abbreviation: "", color: "")))]))
        }
    }


}
