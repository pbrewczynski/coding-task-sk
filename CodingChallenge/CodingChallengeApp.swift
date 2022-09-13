// CodingChallengeApp.swift

import SwiftUI

@main
struct CodingChallengeApp: App {

    var body: some Scene {

        WindowGroup {
          ShiftsView(shiftsStore: ShiftStore(date: Date.distantPast, shifts: [Shift(id:0, start_time: "", end_time: "", premium_rate: false, covid: false, within_distance: 20, facility_type: FacilityType(id: 0, name: "name", color: "#121212"))]))
        }
    }


}
