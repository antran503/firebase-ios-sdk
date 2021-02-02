import FirebaseInAppMessaging
import SwiftUI

// Handle delegate for FIAM actions.
struct InAppMessagingDisplayModifier<DisplayMessage: View>: ViewModifier {
  var closure: (InAppMessagingDisplayMessage, InAppMessagingDisplayDelegate) -> DisplayMessage
  
  @ObservedObject var delegateBridge: DelegateBridge = DelegateBridge()

  func body(content: Content) -> some View {
    let inAppMessage = delegateBridge.inAppMessage
    return content
      .overlay(inAppMessage == nil ? AnyView(EmptyView()) : AnyView(closure(inAppMessage!.0, inAppMessage!.1)))
  }
}

class DelegateBridge: InAppMessagingDisplay, ObservableObject {
  @Published var inAppMessage: (InAppMessagingDisplayMessage, InAppMessagingDisplayDelegate)?  = nil

  init() {
    InAppMessaging.inAppMessaging().messageDisplayComponent = self
  }

  func displayMessage(_ messageForDisplay: InAppMessagingDisplayMessage,
                      displayDelegate: InAppMessagingDisplayDelegate) {
    DispatchQueue.main.async {
      self.inAppMessage = (messageForDisplay, displayDelegate)
    }
  }
}

public extension View {
  func onDisplayInAppMessage<T: View>(closure: @escaping (InAppMessagingDisplayMessage,
                                                          InAppMessagingDisplayDelegate) -> T) -> some View {
    modifier(InAppMessagingDisplayModifier(closure: closure))
  }
}
