// MainView.swift
import SwiftUI
import PhotosUI

struct MainView: View {
    @StateObject private var convVM   = ConversationsViewModel()
    @StateObject private var configVM = ServerConfigViewModel()
    @StateObject private var tasksVM  = ScheduledTasksViewModel()
    @State private   var showingConfig = false
    @State private   var showingTasks  = false

    var body: some View {
        VStack(spacing: 0) {
            // — Pestañas superiores
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(convVM.conversations.indices, id: \.self) { index in
                        Button {
                            convVM.currentConversationIndex = index
                        } label: {
                            Text(convVM.conversations[index].name)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    index == convVM.currentConversationIndex
                                        ? Color.gray
                                        : Color.secondary.opacity(0.2)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                convVM.deleteConversation(at: index)
                            } label: {
                                Label("Eliminar conversación", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        convVM.addNewConversation()
                    } label: {
                        Image(systemName: "plus")
                            .padding(8)
                            .background(Color.secondary.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }

            Divider()

            // — Chat
            NavigationView {
                // 1) Binding al array de mensajes de la conversación activa
                let messagesBinding =
                    $convVM
                        .conversations[convVM.currentConversationIndex]
                        .messages

                // 2) Forzamos remount de ChatView al cambiar de modelo O de pestaña
                Group {
                    ChatView(messages: messagesBinding)
                }
                .id("\(configVM.selectedModel)-\(convVM.currentConversationIndex)")
                .environmentObject(configVM)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingConfig.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingTasks.toggle()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)  // evita caching en iPad
        }
        .sheet(isPresented: $showingConfig) {
            ServerConfigView()
                .environmentObject(configVM)
        }
        .sheet(isPresented: $showingTasks) {
            ScheduledTasksView()
                .environmentObject(tasksVM)
        }
        .onAppear {
            tasksVM.startMonitoring(config: configVM)
        }
    }
}

