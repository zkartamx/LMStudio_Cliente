import SwiftUI

struct ScheduledTasksView: View {
    @EnvironmentObject private var tasksVM: ScheduledTasksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var runDate = Date()
    @State private var prompt = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nueva tarea")) {
                    TextField("Nombre", text: $name)
                    DatePicker("Fecha y hora", selection: $runDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Prompt", text: $prompt)
                    Button("Agregar") {
                        guard !name.isEmpty else { return }
                        tasksVM.addTask(name: name, date: runDate, prompt: prompt)
                        name = ""
                        runDate = Date()
                        prompt = ""
                    }
                }

                Section(header: Text("Tareas programadas")) {
                    if tasksVM.tasks.isEmpty {
                        Text("No hay tareas")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(tasksVM.tasks) { task in
                            VStack(alignment: .leading) {
                                Text(task.name)
                                Text(task.runDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if !task.prompt.isEmpty {
                                    Text(task.prompt)
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete(perform: tasksVM.deleteTask)
                    }
                }
            }
            .navigationTitle("Tareas programadas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

struct ScheduledTasksView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledTasksView()
            .environmentObject(ScheduledTasksViewModel())
    }
}
