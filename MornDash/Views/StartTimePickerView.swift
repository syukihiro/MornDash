import SwiftUI

struct StartTimePickerView: View {
    @Binding var selection: Date

    var body: some View {
        DatePicker(
            "",
            selection: $selection,
            displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .mornDashScreenBackground()
    }
}
