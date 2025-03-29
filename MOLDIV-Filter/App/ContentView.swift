//
//  ContentView.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/28/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel = DIContainer().makeEditorViewModel()
    
    var body: some View {
        EditorView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
