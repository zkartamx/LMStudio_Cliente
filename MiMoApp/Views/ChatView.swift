import SwiftUI
import PhotosUI
import UIKit

// MARK: – ChatView.swift

struct ChatView: View {
    // 1) Binding de mensajes
    @Binding var messages: [ChatMessage]
    // System prompt por pestaña
    @Binding var systemPrompt: String
    // 2) ChatViewModel
    @StateObject private var viewModel: ChatViewModel
    // 3) ConfigVM compartido
    @EnvironmentObject private var configVM: ServerConfigViewModel

    // Control para presentar el picker
    @State private var showingPhotoPicker = false

    init(messages: Binding<[ChatMessage]>, systemPrompt: Binding<String>) {
        _messages     = messages
        _systemPrompt = systemPrompt
        _viewModel    = StateObject(wrappedValue: ChatViewModel(bindingMessages: messages))
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("System prompt…", text: $systemPrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.top, 8)

            // — 1) Lista de mensajes, ocupa todo el espacio disponible
            ChatMessagesView(messages: messages)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(
                            style: StrokeStyle(lineWidth: 1, dash: [4])
                        )
                        .foregroundColor(Color(uiColor: .systemGray4))
                )
                .padding(.horizontal)
                .layoutPriority(1)

            // — 2) Indicador de “Escribiendo…” mientras llegue streaming
            if viewModel.isStreaming {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7, anchor: .center)
                    Text("Escribiendo…")
                        .italic()
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .transition(.opacity)
            }

            // — 3) Miniaturas seleccionadas
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedImages.indices, id: \.self) { i in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.selectedImages[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                                Button {
                                    viewModel.selectedImages.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Divider()

            // — 4) Barra de entrada
            ChatInputBar(
                userInput:      $viewModel.userInput,
                isStreaming:    viewModel.isStreaming,
                selectedImages: viewModel.selectedImages,
                sendAction: {
                    viewModel.sendPrompt(
                        model: configVM.selectedModel,
                        host:  configVM.address,
                        port:  configVM.port,
                        systemPrompt: systemPrompt
                    )
                },
                showImagePicker: {
                    showingPhotoPicker = true
                }
            )
            .environmentObject(configVM)
            .id(configVM.selectedModel) // Fuerza remount si cambia modelo

            // — 5) Botón detener streaming
            if viewModel.isStreaming {
                Button("🔴 Detener respuesta", role: .destructive) {
                    viewModel.stopStreaming()
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Chat")
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(
                selectedImages: $viewModel.selectedImages,
                selectionLimit: 0
            )
        }
    }
}


// MARK: – ChatInputBar

struct ChatInputBar: View {
    @Binding var userInput: String
    let isStreaming:    Bool
    let selectedImages: [UIImage]
    let sendAction:     () -> Void
    let showImagePicker: () -> Void

    @EnvironmentObject private var configVM: ServerConfigViewModel
    @State private var showCameraButton = false

    var body: some View {
        HStack {
            TextField("Escribe tu mensaje…", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)

            Button("Enviar", action: sendAction)
                .disabled(
                    (userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     && selectedImages.isEmpty)
                    || isStreaming
                )

            if showCameraButton {
                Button(action: showImagePicker) {
                    Image(systemName: "camera")
                        .font(.title3)
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal)
        .onAppear {
            showCameraButton = configVM.modelSupportsImages(configVM.selectedModel)
        }
        .onChange(of: configVM.selectedModel) { newModel in
            showCameraButton = configVM.modelSupportsImages(newModel)
        }
    }
}


// MARK: – PhotoPicker (PHPickerViewController)

// MARK: – PhotoPicker (PHPickerViewController)

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    var selectionLimit: Int = 0

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = selectionLimit

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        // Para evitar que SwiftUI lo encaje en un half-sheet
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController,
                                context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        // Referencia fuerte al PhotoPicker
        private let parent: PhotoPicker

        init(parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            // Limpiamos antes de añadir
            parent.selectedImages.removeAll()

            for result in results {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }

                // Capturamos weak self para no crear retain cycle
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    guard
                        let self = self,
                        let image = object as? UIImage
                    else {
                        return
                    }
                    // Volvemos al hilo principal para actualizar el binding
                    DispatchQueue.main.async {
                        self.parent.selectedImages.append(image)
                    }
                }
            }

            picker.dismiss(animated: true)
        }
    }
}



// MARK: – ChatMessagesView & MessageBubble

struct ChatMessagesView: View {
    let messages: [ChatMessage]
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                    }
                }
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    private var maxBubbleWidth: CGFloat {
        UIScreen.main.bounds.width - 32
    }
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading,
               spacing: 8) {
            if !message.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(message.images.indices, id: \.self) { idx in
                            Image(uiImage: message.images[idx])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            if let text = message.text, !text.isEmpty {
                SelectableText(text: text,
                               textColor: message.isUser ? .white : .black)
                    .padding(12)
                    .background(
                        message.isUser ? Color.blue : Color.white
                    )
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity,
                           alignment: message.isUser ? .trailing : .leading)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
        }
        .frame(maxWidth: maxBubbleWidth,
               alignment: message.isUser ? .trailing : .leading)
        .frame(maxWidth: .infinity,
               alignment: message.isUser ? .trailing : .leading)
        .padding(message.isUser ? .leading : .trailing, 50)
        .padding(.vertical, 4)
    }
}


