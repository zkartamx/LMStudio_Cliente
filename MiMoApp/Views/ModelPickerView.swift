//
//  ModelPickerView.swift
//  MiMoApp
//
//  Created by Carlos Daniel Arteaga Hernandez on 13/06/25.
//

// Views/ModelPickerView.swift

import SwiftUI

/// Vista para elegir uno de los modelos disponibles.
/// Se presenta típicamente en un sheet/modal.
struct ModelPickerView: View {
    /// El modelo actualmente seleccionado (binding con el ViewModel).
    @Binding var selectedModel: String
    /// Lista de modelos recuperados desde el servidor.
    let models: [String]
    /// Permite cerrar la vista (cuando se presenta en sheet).
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List(models, id: \.self) { model in
                HStack {
                    Text(model)
                    Spacer()
                    if model == selectedModel {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle()) // para que el tap cubra toda la fila
                .onTapGesture {
                    selectedModel = model
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Modelos disponibles")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ModelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelPickerView(
            selectedModel: .constant("gpt-4o-mini"),
            models: [
                "gpt-4o-mini",
                "gpt-3.5-turbo",
                "qwen2-vl-7b-instruct",
                "custom-vision-model"
            ]
        )
    }
}
