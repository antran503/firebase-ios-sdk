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
  @State var output: String = "No output"
  @State var fetchTime: Date?
  @State var activateTime: Date?

  public init() {
    remoteConfig = RemoteConfig.remoteConfig()
    dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .medium
  }

  var body: some View {
    VStack(alignment: .center, spacing: 10) {
      Text("Remote Config").bold().padding()
      Form {
        TextField("Parameter Name", text: $paramName)
        Button(action: fetchRemoteConfig) {
          Text("Get").frame(maxWidth: .infinity)
        }
      }
      ScrollView {
        Text(output)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
      }.padding()
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
      }.padding([.horizontal, .bottom])
    }
  }

  func fetchRemoteConfig() {
    remoteConfig.fetch { (status, error) -> Void in
      var message: String
      if status == .success {
        message = "Fetched successfully"
        self.fetchTime = Date()

      } else {
        message = "Fetch error: \(error?.localizedDescription ?? "No error available.")"
      }
      print(message)
      self.output = message
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
      self.output = message
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
