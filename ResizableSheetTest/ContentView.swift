//
//  ContentView.swift
//  ResizableSheetTest
//
//

import SwiftUI
import ResizableSheetOverlay


struct ContentView: View {
        // Sheet presentation triggers
    @State private var showStandardSheet = false
    @State private var showToolbarSheet = false
    @State private var showDetentsSheet = false
    @State private var showSizingSheet = false
    
        // Individual size bindings for overlay testing
    @State private var standardSheetSize = CGSize(width: 500, height: 400)
    @State private var toolbarSheetSize = CGSize(width: 500, height: 400)
    @State private var detentsSheetSize = CGSize(width: 500, height: 400)
    @State private var sizingSheetSize = CGSize(width: 500, height: 400)
    
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
            
                // 4. Presentation Sizing Test
            Button("4. Sheet with Presentation Sizing") {
                showSizingSheet = true
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
            // 4. PRESENTATION SIZING TEST OVERLAY
            // ----------------------------------------------------
        .resizableSheetOverlay(
            isPresented: $showSizingSheet,
            sheetSize: $sizingSheetSize,
            minSize: CGSize(width: 320, height: 240),
            maxSize: CGSize(width: 800, height: 600)
        ) {
            PresentationSizingTestSheetView(isPresented: $showSizingSheet)
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

    // MARK: - 4. Presentation Sizing Test Sheet
struct PresentationSizingTestSheetView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Presentation Sizing Test")
                    .font(.headline)
                Spacer()
                Button("Close") { isPresented = false }
            }
            Divider()
            Spacer()
            Text("Testing if native `.presentationSizing` modifier causes layout conflicts or outer boundary clipping.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
            // Native presentation sizing modifier attached inside content
        .presentationSizing(.fitted)
    }
}
