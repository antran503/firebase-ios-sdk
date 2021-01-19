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
          ContentView().onInAppMessage { (message) in
            ZStack {
              RoundedRectangle(cornerRadius: 8.0).stroke(lineWidth: 2.0)
              VStack {
                Image(uiImage: UIImage(data: (message as! InAppMessagingModalDisplay).imageData!.imageRawData!)!)
                  .resizable()
                  .frame(width: 290.0, height: 298.0)
                  .aspectRatio(contentMode: .fit)
                Text((message as! InAppMessagingModalDisplay).title)
                  .font(.title)
                  .multilineTextAlignment(.center)
                  .lineLimit(nil)
                  .fixedSize(horizontal: false, vertical: true)
                Text((message as! InAppMessagingModalDisplay).bodyText!)
                  .font(.body)
                  .multilineTextAlignment(.center)
                  .lineLimit(nil)
                  .fixedSize(horizontal: false, vertical: true)
                  .padding(20)
              }
            }
          }
        }
    }
}

