// ShiftSheetView.swift

import SwiftUI

struct ShiftSheetView:View {

  @Binding var shift: Shift
  var body:some View {

    ZStack {
      Color.from(hex: shift.facility_type.color).ignoresSafeArea()
      VStack {
        Text(shift.facility_type.name)
        Text(shift.skill.name)
        Text(shift.localized_specialty.name).background(Color.from(hex: shift.localized_specialty.specialty.color))
      }
    }
  }
}
