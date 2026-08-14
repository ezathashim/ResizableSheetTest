//
//  ContentView.swift
//  ResizableSheetTest
//
//


import SwiftUI

    // MARK: - Sample Identifiable Data Model
struct TestItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

struct ContentView: View {
        // Sheet presentation triggers
    @State private var showStandardSheet = false
    @State private var showToolbarSheet = false
    @State private var showDetentsSheet = false
    
        // Item-based presentation trigger
    @State private var activeItem: TestItem?
    
        // Individual size bindings for overlay testing
    @State private var standardSheetSize = CGSize(width: 500, height: 400)
    @State private var toolbarSheetSize = CGSize(width: 500, height: 400)
    @State private var detentsSheetSize = CGSize(width: 500, height: 400)
    @State private var itemSheetSize = CGSize(width: 500, height: 400)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ResizableSheetOverlay Test Bench")
                .font(.title2)
                .bold()
                .padding(.bottom, 10)
            
                // 1. Current / Standard View Test
            Button("1. Standard Resizable Sheet") {
                showStandardSheet = true
            }
            .buttonStyle(.borderedProminent)
            
                // 2. Toolbar Close Test
            Button("2. Sheet with Navigation Toolbar") {
                showToolbarSheet = true
            }
            .buttonStyle(.bordered)
            
                // 3. Detents Compatibility Test
            Button("3. Sheet with Presentation Detents") {
                showDetentsSheet = true
            }
            .buttonStyle(.bordered)
            
                // 4. Item-Based Presentation Test
            Button("4. Item-Based Resizable Sheet") {
                activeItem = TestItem(
                    title: "Item Presentation",
                    description: "This sheet was initialized passing an Identifiable model instance."
                )
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(minWidth: 700, minHeight: 600)
            // ----------------------------------------------------
            // 1. STANDARD SHEET OVERLAY
            // ----------------------------------------------------
        .resizableSheetOverlay(
            isPresented: $showStandardSheet,
            sheetSize: $standardSheetSize,
            minSize: CGSize(width: 320, height: 240),
            maxSize: CGSize(width: 800, height: 600)
        ) {
            StandardTestSheetView(isPresented: $showStandardSheet)
        }
            // ----------------------------------------------------
            // 2. TOOLBAR TEST OVERLAY
            // ----------------------------------------------------
        .resizableSheetOverlay(
            isPresented: $showToolbarSheet,
            sheetSize: $toolbarSheetSize,
            minSize: CGSize(width: 350, height: 280),
            maxSize: CGSize(width: 850, height: 650)
        ) {
            ToolbarTestSheetView(isPresented: $showToolbarSheet)
        }
            // ----------------------------------------------------
            // 3. DETENTS TEST OVERLAY
            // ----------------------------------------------------
        .resizableSheetOverlay(
            isPresented: $showDetentsSheet,
            sheetSize: $detentsSheetSize,
            minSize: CGSize(width: 320, height: 240),
            maxSize: CGSize(width: 800, height: 600)
        ) {
            DetentsTestSheetView(isPresented: $showDetentsSheet)
        }
            // ----------------------------------------------------
            // 4. ITEM-BASED SHEET OVERLAY TEST
            // ----------------------------------------------------
        .resizableSheetOverlay(
            item: $activeItem,
            sheetSize: $itemSheetSize,
            minSize: CGSize(width: 320, height: 240),
            maxSize: CGSize(width: 800, height: 600),
            onDismiss: {
                print("Item sheet was dismissed cleanly.")
            }
        ) { item in
            ItemTestSheetView(item: item, activeItem: $activeItem)
        }
    }
}

    // MARK: - 1. Standard Test Sheet
struct StandardTestSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Standard Sheet")
                    .font(.headline)
                Spacer()
                Button("Close") { isPresented = false }
            }
            Divider()
            Spacer()
            Text("Baseline test for handle drag response and sizing bounds.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

    // MARK: - 2. Toolbar Test Sheet
struct ToolbarTestSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Text("Testing top header exclusion zone with navigation bars.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            }
            .navigationTitle("Toolbar Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

    // MARK: - 3. Presentation Detents Test Sheet
struct DetentsTestSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Detents Test")
                    .font(.headline)
                Spacer()
                Button("Close") { isPresented = false }
            }
            Divider()
            Spacer()
            Text("Testing if native `.presentationDetents` conflicts with or overrides `ResizableSheetOverlay` handling.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
            // Native detents modifier attached inside content
        .presentationDetents([.medium, .large])
    }
}

    // MARK: - 4. Item-Based Test Sheet
struct ItemTestSheetView: View {
    let item: TestItem
    @Binding var activeItem: TestItem?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                Button("Close") { activeItem = nil }
            }
            Divider()
            Spacer()
            Text(item.description)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
