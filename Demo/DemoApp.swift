//
//  DemoApp.swift
//  Demo
//
//  Created by 潘令川 on 2024/9/24.
//

import SwiftUI
import Inject
@main
struct DemoApp: App {
  @ObserveInjection var inject // 观察注入事件，强制视图重绘
    var body: some Scene {
        WindowGroup {
            ContentView()
            .enableInjection()
          
        }
    }
}
