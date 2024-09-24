//
//  ContentView.swift
//  Demo
//
//  Created by 潘令川 on 2024/9/24.
//

import SwiftUI

struct ContentView: View {
  @ObserveInjection var inject // 观察注入事件，强制视图重绘
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .enableInjection()
    }
}

#Preview {
    ContentView()
}
