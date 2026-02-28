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
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(quickTasks, id: \.self) { task in
                            Button {
                                inputTask = task
                            } label: {
                                Text(task)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 220)
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
