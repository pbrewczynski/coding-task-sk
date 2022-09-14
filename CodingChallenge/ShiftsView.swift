// ShiftsView.swift

import SwiftUI
import UIKit

struct Response: Codable {
  var data: [DayShift]
}

// https://stackoverflow.com/a/59056440/1364174
struct ActivityIndicator: UIViewRepresentable {

    typealias UIView = UIActivityIndicatorView
    var isAnimating: Bool
    fileprivate var configuration = { (indicator: UIView) in }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}

extension View where Self == ActivityIndicator {
    func configure(_ configuration: @escaping (Self.UIView)->Void) -> Self {
        Self.init(isAnimating: self.isAnimating, configuration: configuration)
    }
}


func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

extension Color {
  static func from(hex: String) -> Color {
    return Color(hexStringToUIColor(hex: hex))
  }
}

struct ShiftsView: View {
//  var shifts: [Shift] = []
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
//              if await ( dayShift.id == results.last?.id ) {
               //}
//                print("After loadnextday")
            //}

//              print("dayShift.id == results.last?.id \(dayShift.id) == \(results.last?.id.description)")
//                  DispatchQueue.global(qos: .userInitiated).async {
//                    Task {
//                      await loadNextDay()
//                    }
//                  }
//              }
              }

            }
          }
        }
      .cornerRadius(5)
      .navigationTitle("Shifts for Dallas, TX").sheet(isPresented: $isShowingSheet) {
          ShiftSheetView(shift: $shiftForSheet)
        }
    }.onAppear() {
      print("before loadDataForAmount")
      loadDataForAmountOf(days: 3)
      print("after loadDataForAmount")
    }
  }

  func moveDate(_ date: Date, byDays days: Int) -> Date? {
    return Calendar.current.date(byAdding: .day, value: days, to: date)
  }

//  func updateUI(with data: [DayShift]) {
//    results.append(contentsOf: data)
//    isLoadingIndicatorShown = false
//  }

  func loadDataForAmountOf(days amountOfDaysToLoad: UInt, from: Date = Date()) {

    guard let url = URL(string: "https://staging-app.shiftkey.com/api/v2/available_shifts") else {
      return
    }
    guard let endOfWeekDate = moveDate(from, byDays: Int(amountOfDaysToLoad-1)) else {
      return
    }
    let iso8601formatter = ISO8601DateFormatter()
    iso8601formatter.formatOptions = [.withFullDate]
    let firstDateToLoad = iso8601formatter.string(from: from)
    let lastDateToLoad = iso8601formatter.string(from: endOfWeekDate)
    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    urlComponents?.queryItems = [
      URLQueryItem(name: "type", value: "list"),
      URLQueryItem(name: "adress", value: "Dallas, TX"),
      URLQueryItem(name: "start", value: firstDateToLoad),
      URLQueryItem(name: "end", value: lastDateToLoad)
    ]
    guard let urlWithGetParameters = urlComponents?.url else {
      return
    }
    print("urlWithGetParameters: \(urlWithGetParameters)")

    DispatchQueue.global().async {
      let data = try! Data.init(contentsOf: urlWithGetParameters)
//      let (data, _) = try! URLSession.shared.data(from: urlWithGetParameters)
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
//    do {
//      DispatchQueue.global(qos: .userInitiated).async {
//          do {
//            let (data, _) = try URLSession.shared.data(from: urlWithGetParameters)
//            if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
//            // results = decodedResponse.data
//            DispatchQueue.main.async {
//              results.append(contentsOf: decodedResponse.data)
//            }
//          } else {
//            print("decoding data unsuccessfull")
//          }
//            DispatchQueue.main.async {
//              isLoadingIndicatorShown = false
//            }
//          } catch {
//            print("invalid something")
//          }
//      }

//    } catch {
//      print("Invalid data")
//    }




struct ShiftsView_Previews: PreviewProvider {
  static var previews: some View {
    ShiftsView( shiftsStore: ShiftStore(date: Date.distantPast, shifts: [Shift(shift_id:0, start_time: "", end_time: "", premium_rate: false, covid: false, within_distance: 20, facility_type: FacilityType(id: 1, name: "namefacility", color: "#121212"), skill: Skill(id: 0, name: "", color: ""), localized_specialty: LocalizedSpeciality(id: 0, name: "", abbreviation: "", specialty: Speciality(id: 0, name: "", abbreviation: "", color: "") ) ) ]) )
  }
}

// https://stackoverflow.com/a/70576093/1364174
@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    func data(from url: URL) async throws -> (Data, URLResponse) {
         try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                 guard let data = data, let response = response else {
                     let error = error ?? URLError(.badServerResponse)
                     return continuation.resume(throwing: error)
                 }

                 continuation.resume(returning: (data, response))
             }

             task.resume()
        }
    }
}

// https://stackoverflow.com/a/72251152/1364174
extension View {
    @available(iOS, deprecated: 15.0, message: "This extension is no longer necessary. Use API built into SDK")
    func task(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
        self.onAppear {
            Task(priority: priority) {
                await action()
            }
        }
    }
}


//      let dataString = String(decoding: data, as: UTF8.self)
//      do {
//        try JSONDecoder().decode(Response.self, from: data)
//      } catch {
//        print("error : \(error)")
//      }
