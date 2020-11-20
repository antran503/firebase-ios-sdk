//
//  ContentView.swift
//  RemoteConfigSwiftSample
//
//  Created by Karen Zeng on 11/16/20.
//  Copyright © 2020 Firebase. All rights reserved.
//

import SwiftUI
import FirebaseRemoteConfig

enum ValueType: String, Identifiable {
  case string
  case boolean
  case int

  var id: String { rawValue }
}

var remoteConfig: RemoteConfig!
var dateFormatter: DateFormatter!

struct ContentView: View {
  @State var paramName: String = ""
  @State var valueType: ValueType = ValueType.string
  @State var output: [String] = []
  @State var fetchTime: Date?
  @State var activateTime: Date?

  public init() {
    remoteConfig = RemoteConfig.remoteConfig()
    dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .medium
  }

  var body: some View {
    VStack {
      Text("Remote Config").bold().padding()
      VStack(alignment: .center, spacing: 0) {
        ScrollView {
          ScrollViewReader { scrollView in
            VStack(spacing: 0) {
              ForEach(self.output.indices, id: \.self) { i in
                Text(self.output[i])
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .font(.system(size: 14, design: .monospaced))
                  .id(i)
              }.onAppear {
                withAnimation { scrollView.scrollTo(self.output.count - 1) }
              }
            }.fixedSize(horizontal: false, vertical: true).padding()

            if self.output.count == 0 {
              HStack {
                Spacer()
              }
            }
          }
        }.background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
        Button(action: { self.output = [] }) {
          Text("Clear logs")
            .font(.system(size: 14))
        }.frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGray6))
      }.zIndex(1)
      VStack(alignment: .center) {
        HStack {
          TextField("Parameter Name", text: $paramName).autocapitalization(.none)
          Picker("ValueType", selection: $valueType) {
            Text("String").tag(ValueType.string).font(.system(size: 14))
            Text("Boolean").tag(ValueType.boolean).font(.system(size: 14))
            Text("Int").tag(ValueType.int).font(.system(size: 14))
          }.frame(width: 80, height: 60).clipped()
          Button(action: getParameter) {
            Text("Get").padding()
          }
        }.padding([.horizontal])
        Divider()
        HStack(alignment: .center, spacing: 10) {
          Button(action: fetchRemoteConfig) {
            Text("Fetch").frame(maxWidth: .infinity)
          }
          Button(action: activateRemoteConfig) {
            Text("Activate").frame(maxWidth: .infinity)
          }
        }.padding()
        HStack(alignment: .center, spacing: 10) {
          Text("Last fetched:\n" +
            (fetchTime != nil ? dateFormatter.string(from: fetchTime!) : "-"))
            .foregroundColor(Color.gray)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
          Text("Last activated:\n" +
            (activateTime != nil ? dateFormatter.string(from: activateTime!) : "-"))
            .foregroundColor(Color.gray)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }.padding().background(Color(UIColor.systemGray6))
      }
    }
  }

  func fetchRemoteConfig() {
    remoteConfig.fetch(withExpirationDuration: 0) { (status, error) -> Void in
      var message: String
      if status == .success {
        message = "Fetched successfully"
        self.fetchTime = Date()

      } else {
        message = "Fetch error: \(error?.localizedDescription ?? "No error available.")"
      }
      print(message)
      self.log(message)
    }
  }

  func activateRemoteConfig() {
    remoteConfig.activate { (activated, error) -> Void in
      var message: String
      if activated {
        message = "Activated updated config"
        self.activateTime = Date()
      } else if error == nil {
        message = "No change in config"
      } else {
        message = "Activate error: \(error?.localizedDescription ?? "No error available")"
      }
      print(message)
      self.log(message)
    }
  }

  func getParameter() {
    let value = remoteConfig.configValue(forKey: paramName)
    log("Parameter: \"\(paramName)\"")
    switch valueType {
    case ValueType.string:
      log("Value(String): \"\(value.stringValue ?? "")\"")
    case ValueType.boolean:
      log("Value(Bool): \(String(value.boolValue))")
    case ValueType.int:
      log("Value(Int): \(value.numberValue.stringValue)")
    }
    log("Source: \(getSourceName(value.source))")
  }

  func log(_ message: String) {
    output.append("[\(dateFormatter.string(from: Date()))] \(message)\n")
  }

  func getSourceName(_ source: RemoteConfigSource) -> String {
    switch source {
    case RemoteConfigSource.static:
      return "STATIC"
    case RemoteConfigSource.default:
      return "DEFAULT"
    case RemoteConfigSource.remote:
      return "REMOTE"
    default:
      return "UNKNOWN"
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
