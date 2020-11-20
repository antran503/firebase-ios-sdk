//
//  ContentView.swift
//  RemoteConfigSwiftSample
//
//  Created by Karen Zeng on 11/16/20.
//  Copyright © 2020 Firebase. All rights reserved.
//

import SwiftUI
import FirebaseRemoteConfig

var remoteConfig: RemoteConfig!
var dateFormatter: DateFormatter!

struct ContentView: View {
  @State var paramName: String = ""
  @State var output: String = ""
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
          Text(output)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(5)
            .font(.system(size: 14))
            .padding()
        }.background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all))
        Button(action: { self.output = "" }) {
          Text("Clear logs")
            .font(.system(size: 14))
        }.frame(maxWidth: .infinity).padding().background(Color(UIColor.systemGray6))
      }
      VStack(alignment: .center) {
        HStack {
          TextField("Parameter Name", text: $paramName).autocapitalization(.none)
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
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
          Text("Last activated:\n" +
            (activateTime != nil ? dateFormatter.string(from: activateTime!) : "-"))
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
    log("Getting parameter: \"\(paramName)\"")
    log("Value: \"\(value.stringValue ?? "")\"")
    log("Source: \(getSourceName(value.source))")
  }

  func log(_ message: String) {
    output += "[\(dateFormatter.string(from: Date()))] \(message)\n"
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
