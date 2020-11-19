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

struct ContentView: View {
  @State var paramName: String = ""

    public init() {
        remoteConfig = RemoteConfig.remoteConfig()
    }
    
    var body: some View {
        VStack() {
          Text("Remote Config").bold().padding()
          Divider()
          Form {
            TextField("Parameter Name", text: $paramName)
            Button(action: fetchRemoteConfig) {
              Text("Get").frame(maxWidth:.infinity)
            }
          }
          HStack(alignment: .center, spacing: 10) {
            Button(action: fetchRemoteConfig) {
              Text("Fetch").frame(maxWidth:.infinity)
            }
            Button(action: activateRemoteConfig) {
              Text("Activate").frame(maxWidth:.infinity)
            }
          }.padding()
          HStack(alignment: .center, spacing: 10) {
            Text("fetchTime").frame(maxWidth:.infinity)
            Text("activateTime").frame(maxWidth:.infinity)
          }.padding([.leading, .bottom, .trailing])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func fetchRemoteConfig() -> Void {
    remoteConfig.fetch() { (status, error) -> Void in
        if status == .success {
            print("Fetched successfully")
        } else {
            print("Fetch error:", error?.localizedDescription ?? "No error available.")
        }
    }
}

func activateRemoteConfig() -> Void {
    remoteConfig.activate() { (activated, error) -> Void in
        if activated {
            print("Activated updated config")
        } else if error == nil  {
            print("Did not activate config")
        } else {
            print("Activate error:", error?.localizedDescription ?? "No error available.")
        }
    }
}
