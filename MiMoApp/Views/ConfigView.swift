import SwiftUI

struct ConfigView: View {
    // Usamos TU ServerConfigViewModel
    @EnvironmentObject private var configVM: ServerConfigViewModel
    @Environment(\.dismiss)    private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // MARK: – Servidor
                Section(header: Text("Servidor LM Studio")) {
                    TextField("Dirección IP", text: $configVM.address)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    TextField("Puerto", text: $configVM.port)
                        .keyboardType(.numberPad)
                }

                // MARK: – Descargar Modelos
                Section {
                    Button {
                        Task { await configVM.fetchModels() }
                    } label: {
                        HStack {
                            if configVM.isLoading {
                                ProgressView()
                            }
                            Text("Recuperar modelos")
                        }
                    }
                    .disabled(configVM.isLoading)

                    if let err = configVM.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                    }
                }

                // MARK: – Selección de Modelo
                if !configVM.models.isEmpty {
                    Section(header: Text("Modelos encontrados")) {
                        ForEach(configVM.models, id: \.self) { model in
                            HStack {
                                Text(model).lineLimit(1)
                                Spacer()
                                // icono si soporta imagen
                                if configVM.modelSupportsImages(model) {
                                    Image(systemName: "photo")
                                }
                                // check en el seleccionado
                                if model == configVM.selectedModel {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                configVM.selectedModel = model
                                // updateSupportsImageInput() se llamará en didSet
                            }
                        }
                    }
                }
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
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

