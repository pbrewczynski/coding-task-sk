// ShiftsView.swift

import SwiftUI
import UIKit

struct Response: Codable {
  var data: [DayShift]
}

extension String: Error {}

struct ShiftsView: View {

//  var shifts: [Shift] = []

  @StateObject var viewModel = ShiftResultsViewModel()

  @State private var results = [DayShift]()
  @ObservedObject var shiftsStore: ShiftStore

  @State private var isShowingSheet = false
  @State private var shiftForSheet = Shift(shift_id: 0, start_time: "", end_time: "", premium_rate: false, covid: false, facility_type: FacilityType(id: 0, name: "", color: "  "),skill: Skill(id: 0, name: "", color: ""), localized_specialty: LocalizedSpeciality(id: 0, name: "", abbreviation: "",specialty: Speciality(id: 0, name: "", abbreviation: "", color: "")))

  @State private var isLoadingIndicatorShown = true

  var body: some View {
    NavigationView {
      VStack {
        List {
          if isLoadingIndicatorShown {
            HStack {
              Text("Loading shifts... ")
              ActivityIndicator(isAnimating: true)
              .configure { $0.color = .black }
            }
          }

          ForEach(results) { dayShift in
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
               loadNextDayIfNeeded(dayShift: dayShift)
            }
          }
        }
      }
      .navigationTitle("Shifts for Dallas, TX").sheet(isPresented: $isShowingSheet) {
          ShiftSheetView(shift: $shiftForSheet)
        }
    }.onAppear() {
//      Task {
//        await viewModel.executeQuery(fromDate: Date(), amountOfDays: 3)
//      }
      print("before loadDataForAmount")
      loadDataForAmountOf(days: 3)
      print("after loadDataForAmount")
    }
//    .refreshable {
//      print("refreshed")
//    }
  }

  func conctructShiftsUrlRequestFor(startDate: Date, andAmountOfDays amountOfDays: UInt) -> URL? {

    guard let url = URL(string: "https://staging-app.shiftkey.com/api/v2/available_shifts") else {
      return nil
    }
    guard let endOfWeekDate = moveDate(startDate, byDays: Int(amountOfDays-1)) else {
      return nil
    }
    let iso8601formatter = ISO8601DateFormatter()
    iso8601formatter.formatOptions = [.withFullDate]
    let firstDateToLoad = iso8601formatter.string(from: startDate)
    let lastDateToLoad = iso8601formatter.string(from: endOfWeekDate)
    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    urlComponents?.queryItems = [
      URLQueryItem(name: "type", value: "list"),
      URLQueryItem(name: "adress", value: "Dallas, TX"),
      URLQueryItem(name: "start", value: firstDateToLoad),
      URLQueryItem(name: "end", value: lastDateToLoad)
    ]
    guard let urlWithGetParameters = urlComponents?.url else {
      return nil
    }
    print("urlWithGetParameters: \(urlWithGetParameters)")
    return urlWithGetParameters
  }

  func moveDate(_ date: Date, byDays days: Int) -> Date? {
    return Calendar.current.date(byAdding: .day, value: days, to: date)
  }




  func loadDataForAmountOf(days amountOfDaysToLoad: UInt, from: Date = Date()) {

    guard let url = conctructShiftsUrlRequestFor(startDate: from, andAmountOfDays: amountOfDaysToLoad) else {
      return
    }



    DispatchQueue.global().async {
      let data = try! Data.init(contentsOf: url)
//    let (data, _) = try! URLSession.shared.data(from: urlWithGetParameters)
      if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
        DispatchQueue.main.async {
          results.append(contentsOf: decodedResponse.data)
          isLoadingIndicatorShown = false
        }
      }
    }
  }

  func loadNextDayIfNeeded(dayShift: DayShift) {

    if dayShift.id == results.last?.id {
      guard let lastDate = results.last?.dateAsDate else {
        return
      }
      guard let nextDate = moveDate(lastDate, byDays: 1) else {
        return
      }
      print("lastDate: \(lastDate.description)")
      print("nextDate: \(nextDate.description)")
      loadDataForAmountOf(days: 1, from: nextDate)
    }
  }
}

struct ShiftsView_Previews: PreviewProvider {
  static var previews: some View {
    ShiftsView( shiftsStore: ShiftStore(date: Date.distantPast, shifts: [Shift(shift_id:0, start_time: "", end_time: "", premium_rate: false, covid: false, within_distance: 20, facility_type: FacilityType(id: 1, name: "namefacility", color: "#121212"), skill: Skill(id: 0, name: "", color: ""), localized_specialty: LocalizedSpeciality(id: 0, name: "", abbreviation: "", specialty: Speciality(id: 0, name: "", abbreviation: "", color: "") ) ) ]) )
  }
}
