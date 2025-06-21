import SwiftUI

struct ScheduledTasksView: View {
    @EnvironmentObject private var tasksVM: ScheduledTasksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var schedule = ""
    @State private var prompt = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nueva tarea")) {
                    TextField("Nombre", text: $name)
                    TextField("Cron", text: $schedule)
                    TextField("Prompt", text: $prompt)
                    Button("Agregar") {
                        guard !name.isEmpty, !schedule.isEmpty else { return }
                        tasksVM.addTask(name: name, schedule: schedule, prompt: prompt)
                        name = ""
                        schedule = ""
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
                                Text(task.schedule)
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
