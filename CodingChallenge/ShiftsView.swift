// ShiftsView.swift
// The main view should include a list of shifts. If you tap on a shift it should show a modal shift details view. Be creative and show us your best work.

import SwiftUI

struct Response: Codable {
  var data: [DayShift]
}

struct DayShift: Codable, Identifiable{
  var date: String
  var id: String {
    return date
  }
  var shifts: [Shift]
}

struct ShiftsView: View {
  var shifts: [Shift] = []
  @State private var results = [DayShift]()
  @ObservedObject var shiftsStore: ShiftStore

  var body: some View {
    NavigationView {
      VStack {
        List {
          ForEach(results) { dayShift in
            Section(header: Text(dayShift.date)) {
              ForEach(dayShift.shifts) { shift in
                NavigationLink(shift.facility_type.name) {
                  Text("Facility Type: \(shift.facility_type.name)")
                }
              }
            }
          }
        }.navigationTitle("Shifts for Dallas, TX")
      }
    }.task {
      await loadData()
    }
  }

  func loadData() async {
    guard let url = URL(string: "https://staging-app.shiftkey.com/api/v2/available_shifts") else {
      return
    }
    let calendar = Calendar.current
    guard let endOfWeekDate = calendar.date(byAdding: .day, value: 7, to: Date()) else {
      return
    }

    let iso8601formatter = ISO8601DateFormatter()
    iso8601formatter.formatOptions = [.withFullDate]

    let todayDateParamValue = iso8601formatter.string(from: Date()) // need to use appropriate locale for timezone
    let endOfWeekDateParamValue = iso8601formatter.string(from: endOfWeekDate)

    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    urlComponents?.queryItems = [
      URLQueryItem(name: "type", value: "list"),
      URLQueryItem(name: "adress", value: "Dallas, TX"),
      URLQueryItem(name: "start", value: todayDateParamValue),
      URLQueryItem(name: "end", value: endOfWeekDateParamValue)
    ]

    guard let urlWithGetParameters = urlComponents?.url else {
      return
    }

    print("urlWithGetParameters: \(urlWithGetParameters)")

    do {
      let (data, _) = try await URLSession.shared.data(from: urlWithGetParameters)
      let dataString = String(decoding: data, as: UTF8.self)

      do {
        try JSONDecoder().decode(Response.self, from: data)
      } catch {
        print("error : \(error)")
      }

      if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
        results = decodedResponse.data
      } else {
        print("decoding data unsuccessfull")
      }

//      print("results: \(results)")

    } catch {
      print("Invalid data")
    }
  }
}

struct ShiftsView_Previews: PreviewProvider {
  static var previews: some View {
    ShiftsView( shiftsStore: ShiftStore(date: Date.distantPast, shifts: [Shift(id:0, start_time: "", end_time: "", premium_rate: false, covid: false, within_distance: 20, facility_type: FacilityType(id: 1, name: "namefacility", color: "#121212"))]) )
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
