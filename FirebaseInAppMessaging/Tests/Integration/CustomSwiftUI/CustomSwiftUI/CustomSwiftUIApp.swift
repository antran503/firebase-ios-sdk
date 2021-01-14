//
//  CustomSwiftUIApp.swift
//  CustomSwiftUI
//
//  Created by Chris Tibbs on 1/8/21.
//

import SwiftUI
import FirebaseCore
import FirebaseInAppMessaging
import FirebaseInAppMessagingSwift

@main
struct CustomSwiftUIApp: App {
  
  init() {
    FirebaseApp.configure()
  }
  
    var body: some Scene {
        WindowGroup {
          ContentView().onIAM { (message) in
            // let modal = message as! InAppMessagingModalDisplay
            return VStack {
              Button(action: {
                delegate.dismiss
              }, label: {
                Text("X")
              })
              Text((message as! InAppMessagingModalDisplay).title)
              Text((message as! InAppMessagingModalDisplay).bodyText!)
            }
          }
        }
    }
}
