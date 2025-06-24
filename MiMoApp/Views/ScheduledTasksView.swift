import SwiftUI
import UIKit
import PhotosUI

struct ScheduledTasksView: View {
    @EnvironmentObject private var tasksVM: ScheduledTasksViewModel
    @EnvironmentObject private var configVM: ServerConfigViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var runDate = Date()
    @State private var prompt = ""
    @State private var images: [UIImage] = []
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nueva tarea")) {
                    TextField("Nombre", text: $name)
                    DatePicker("Fecha y hora", selection: $runDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Prompt", text: $prompt)
                    if configVM.supportsImageInput {
                        if !images.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(images.indices, id: \.self) { i in
                                        Image(uiImage: images[i])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipped()
                                            .cornerRadius(8)
                                            .overlay(
                                                Button {
                                                    images.remove(at: i)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                }
                                                .offset(x: 6, y: -6)
                                                , alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                        }
                        Button("Seleccionar imágenes") { showPicker = true }
                    }
                    Button("Agregar") {
                        guard !name.isEmpty else { return }
                        let data = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
                        tasksVM.addTask(name: name, date: runDate, prompt: prompt, images: data)
                        name = ""
                        runDate = Date()
                        prompt = ""
                        images = []
                    }
                }

                Section(header: Text("Tareas programadas")) {
                    if tasksVM.tasks.isEmpty {
                        Text("No hay tareas")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(tasksVM.tasks) { task in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text(task.name)
                                    Text(task.runDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if !task.imageDatas.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack {
                                                ForEach(task.imageDatas, id: \.self) { data in
                                                    if let img = UIImage(data: data) {
                                                        Image(uiImage: img)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 60, height: 60)
                                                            .cornerRadius(8)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if !task.prompt.isEmpty {
                                        Text(task.prompt)
                                            .font(.caption)
                                    }
                                    if let log = task.responseLog {
                                        Text(log)
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                            .textSelection(.enabled)
                                            .contextMenu {
                                                Button {
                                                    UIPasteboard.general.string = log
                                                } label: {
                                                    Label("Copiar", systemImage: "doc.on.doc")
                                                }
                                            }
                                    }
                                }

                                Spacer()

                                if task.executedAt != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
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
            .sheet(isPresented: $showPicker) {
                PhotoPicker(selectedImages: $images, selectionLimit: 0)
            }
        }
    }
}

struct ScheduledTasksView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduledTasksView()
            .environmentObject(ScheduledTasksViewModel())
            .environmentObject(ServerConfigViewModel())
    }
}
