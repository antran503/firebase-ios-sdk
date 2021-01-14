import FirebaseInAppMessaging
import SwiftUI

// Handle delegate for FIAM actions.
struct InAppMessagingDisplayModifier<DisplayMessage: View>: ViewModifier {
  var closure: (InAppMessagingDisplayMessage) -> DisplayMessage
  // @State var inAppMessage: InAppMessagingDisplayMessage?
  @ObservedObject var delegateBridge: DelegateBridge = DelegateBridge()

  func body(content: Content) -> some View {
    let inAppMessage = delegateBridge.inAppMessage
    return content
      .overlay(inAppMessage == nil ? AnyView(EmptyView()) : AnyView(closure(inAppMessage!)))
  }
}

class DelegateBridge: InAppMessagingDisplay, InAppMessagingDisplayDelegate, ObservableObject {
  @Published var inAppMessage: InAppMessagingDisplayMessage? = nil

  init() {
    InAppMessaging.inAppMessaging().messageDisplayComponent = self
    InAppMessaging.inAppMessaging().delegate = self
  }

  func displayMessage(_ messageForDisplay: InAppMessagingDisplayMessage,
                      displayDelegate: InAppMessagingDisplayDelegate) {
    print("FIRFIRFIR Here's a message")
    DispatchQueue.main.async {
      self.inAppMessage = messageForDisplay
    }
  }
  
  func messageDismissed(_ inAppMessage: InAppMessagingDisplayMessage,
                        dismissType: FIRInAppMessagingDismissType) {
    inAppMessage = nil
  }
}

public extension View {
  func onIAM<T: View>(closure: @escaping (InAppMessagingDisplayMessage) -> T) -> some View {
    modifier(InAppMessagingDisplayModifier(closure: closure))
  }
}
