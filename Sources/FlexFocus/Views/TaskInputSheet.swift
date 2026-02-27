import SwiftUI

struct TaskInputSheet: View {
    @Binding var inputTask: String
    @FocusState private var isInputFocused: Bool
    let quickTasks: [String]
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("本次专注任务")
                .font(.title3.bold())

            TextField("输入任务", text: $inputTask)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit(onSubmit)

            if !quickTasks.isEmpty {
                Text("历史任务快速选择")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(quickTasks, id: \.self) { task in
                            Button(task) {
                                inputTask = task
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .frame(maxHeight: 140)
            }

            HStack {
                Spacer()
                Button("取消", action: onCancel)
                Button("开始") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                isInputFocused = true
            }
        }
    }
}
