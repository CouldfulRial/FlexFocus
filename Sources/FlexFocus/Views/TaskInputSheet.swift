import SwiftUI

struct CategorySelectionSheet: View {
    @Binding var selectedCategory: FocusCategory
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Select a focus category")
                .font(.title3.bold())

            Picker("Category", selection: $selectedCategory) {
                ForEach(FocusCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.radioGroup)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                Button("Start", action: onSubmit)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
