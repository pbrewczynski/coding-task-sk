// Created by pbrewczynski on 15/09/2022.

import Foundation

class ShiftResultsViewModel: ObservableObject {
  @Published var result = Response(data: [])
  @Published var isLoadingNewDay = false

  @MainActor
  func executeQuery(fromDate: Date, amountOfDays: UInt) async {
    isLoadingNewDay = true

    let response = await loadDataForAmountOfNew(days: amountOfDays, from: fromDate)
    result.data.append(contentsOf: response.data)

    isLoadingNewDay = false
  }

  func loadDataForAmountOfNew(days amountOfDaysToLoad: UInt, from: Date = Date()) async -> Response {
    guard let url = conctructShiftsUrlRequestFor(startDate: from, andAmountOfDays: amountOfDaysToLoad) else {
      return Response(data: [])
    }
    do {
      let request = URLRequest(url: url)

      if #available(iOS 15.0, *) {

        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
          throw "Invalid response"
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response
      } else {
        print("Running on ios 14 and that's bad ")
        // Fallback on earlier versions
        return Response(data: [])
      }

    } catch {
      return Response(data: [])
    }
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

}
