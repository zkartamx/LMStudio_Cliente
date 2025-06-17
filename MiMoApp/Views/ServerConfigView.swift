// ServerConfigView.swift
import SwiftUI

struct ServerConfigView: View {
    // ① Usa el mismo VM que viene de MainView
    @EnvironmentObject private var configVM: ServerConfigViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            Form {
                serverSection
                configurationSection
                modelsSection
                errorSection
                debugSection
            }
            .navigationTitle("Configuración")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        configVM.saveConfiguration()
                        dismiss()
                    }
                    .disabled(configVM.address.isEmpty || configVM.port.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        // ② Carga una sola vez los modelos en el mismo VM
        .task {
            await configVM.fetchModels()
        }
    }

    // MARK: – Servidor
    private var serverSection: some View {
        Section(header: Text("Servidor LM Studio")) {
            TextField("Dirección IP", text: $configVM.address)
                .keyboardType(.numbersAndPunctuation)
                .autocapitalization(.none)

            TextField("Puerto", text: $configVM.port)
                .keyboardType(.numberPad)
        }
    }

    // MARK: – Guardar / Eliminar
    private var configurationSection: some View {
        Section {
            Button("Eliminar configuración", role: .destructive) {
                showDeleteAlert = true
            }
            .alert("¿Eliminar configuración?", isPresented: $showDeleteAlert) {
                Button("Eliminar", role: .destructive) {
                    configVM.clearConfiguration()
                }
                Button("Cancelar", role: .cancel) { }
            }
        }
    }

    // MARK: – Modelos
    private var modelsSection: some View {
        Section(header: Text("Modelos encontrados")) {
            if configVM.isLoading {
                ProgressView("Cargando modelos…")
            } else if configVM.models.isEmpty {
                Text("Pulsa 'Recuperar modelos'")
                    .foregroundColor(.secondary)
            } else {
                ForEach(configVM.models, id: \.self) { model in
                    HStack {
                        Text(model).lineLimit(1)

                        // icono si soporta imagen
                        if configVM.modelSupportsImages(model) {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        // check en el seleccionado
                        if model == configVM.selectedModel {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        configVM.selectedModel = model
                    }
                }
            }

            Button("Recuperar modelos") {
                Task { await configVM.fetchModels() }
            }
            .disabled(configVM.isLoading)
        }
    }

    // MARK: – Error
    @ViewBuilder
    private var errorSection: some View {
        if let err = configVM.errorMessage {
            Section {
                Text("Error: \(err)")
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: – Debug
    private var debugSection: some View {
        Section(header: Text("Debug")) {
            Text("IP: \(configVM.address)")
            Text("Puerto: \(configVM.port)")
            Text("Modelo actual: \(configVM.selectedModel)")
            HStack {
                Text("Soporta imágenes:")
                Spacer()
                Label(configVM.supportsImageInput ? "Sí" : "No",
                      systemImage: configVM.supportsImageInput
                          ? "checkmark.circle.fill"
                          : "xmark.octagon")
                    .foregroundColor(configVM.supportsImageInput ? .green : .red)
            }
            Text("Versión: \(configVM.appVersion)")
        }
    }
}

