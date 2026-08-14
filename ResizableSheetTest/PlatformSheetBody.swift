//
//  UIKitSheetTestView.swift
//  ResizableSheetTest
//
//  Exercises both uiKitResizableSheet variants (Bool and item) so you can A/B
//  them the same way. The sheet body dismisses via @Environment(\.dismiss);
//  the presenter's viewDidDisappear resets isPresented/item on every route, so
//  no .onDisappear or binding-flip is needed in the body.
//

import SwiftUI


    // MARK: - Bool sheet body

struct PlatformBoolSheetBody: View {
    @Binding var size: CGSize
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bool Sheet").font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            Spacer()
            Text("\(Int(size.width)) × \(Int(size.height))")
                .font(.system(.title2, design: .monospaced))
            Text("Drag the trailing edge, bottom edge, or corner")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

    // MARK: - Item sheet body

struct PlatformItemSheetBody: View {
    let item: TestItem
    @Binding var size: CGSize
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(item.title).font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(size.width)) × \(Int(size.height))")
                .font(.system(.title2, design: .monospaced))
            Text("Item id: \(item.id.uuidString.prefix(8))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

