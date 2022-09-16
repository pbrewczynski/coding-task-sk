// ShiftsView.swift

import SwiftUI
import UIKit

struct Response: Codable {
  var data: [DayShift]
}

extension String: Error {}

struct ShiftsView: View {

  @StateObject var viewModel = ShiftResultsViewModel()

  @ObservedObject var shiftsStore: ShiftStore

  @State private var isShowingSheet = false
  @State private var shiftForSheet = Shift(shift_id: 0, start_time: "", end_time: "", premium_rate: false, covid: false, facility_type: FacilityType(id: 0, name: "", color: "  "),skill: Skill(id: 0, name: "", color: ""), localized_specialty: LocalizedSpeciality(id: 0, name: "", abbreviation: "",specialty: Speciality(id: 0, name: "", abbreviation: "", color: "")))

  @State private var isLoadingIndicatorShown = true

  var body: some View {
    NavigationView {
      VStack {
        List {
          if viewModel.isLoadingNewDay {
            HStack {
              Text("Loading shifts... ")
              ActivityIndicator(isAnimating: true)
              .configure { $0.color = .black }
            }
          }

          ForEach(viewModel.result.data) { dayShift in
            Section(header: Text(dayShift.date)) {
              ForEach(dayShift.shifts) { shift in

                VStack(spacing: 0) {
                  HStack(spacing: 0){
                    Text(shift.facility_type.name)
                    Spacer()
                    Text(shift.skill.name)
                  }
                  HStack(spacing: 0) {
                    Text("\(shift.localized_specialty.name)").frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("\(shift.start_timeOnly)-\(shift.end_timeOnly)")
                  }
                }
                .listRowBackground( Color(hexStringToUIColor(hex: shift.facility_type.color)) )
                .onTapGesture {
                  shiftForSheet = shift
                  isShowingSheet.toggle()
                }
              }
            }.onAppear() {
              Task {
                await loadNextDayIfNeededWithViewModel(dayShiftAppeared: dayShift)
              }
            }
          }
        }
      }
      .navigationTitle("Shifts for Dallas, TX").sheet(isPresented: $isShowingSheet) {
          ShiftSheetView(shift: $shiftForSheet)
        }
    }.onAppear() {
      Task {
        await viewModel.executeQuery(fromDate: Date(), amountOfDays: 7)
      }
    }
  }

  func moveDate(_ date: Date, byDays days: Int) -> Date? {
    return Calendar.current.date(byAdding: .day, value: days, to: date)
  }

  func loadNextDayIfNeededWithViewModel(dayShiftAppeared: DayShift) async {

    if viewModel.result.data.last?.id == dayShiftAppeared.id {
      guard let lastDate = viewModel.result.data.last?.dateAsDate else {
        return
      }
      guard let nextDate = moveDate(lastDate, byDays: 1) else {
        return
      }
      await viewModel.executeQuery(fromDate: nextDate, amountOfDays: 1)
    }
  }
}

struct ShiftsView_Previews: PreviewProvider {
  static var previews: some View {
    ShiftsView( shiftsStore: ShiftStore(date: Date.distantPast, shifts: [Shift(shift_id:0, start_time: "", end_time: "", premium_rate: false, covid: false, within_distance: 20, facility_type: FacilityType(id: 1, name: "namefacility", color: "#121212"), skill: Skill(id: 0, name: "", color: ""), localized_specialty: LocalizedSpeciality(id: 0, name: "", abbreviation: "", specialty: Speciality(id: 0, name: "", abbreviation: "", color: "") ) ) ]) )
  }
}
