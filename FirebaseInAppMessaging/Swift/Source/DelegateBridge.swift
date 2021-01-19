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

class DelegateBridge: InAppMessagingDisplay, ObservableObject {
  @Published var inAppMessage: InAppMessagingDisplayMessage? = nil

  init() {
    InAppMessaging.inAppMessaging().messageDisplayComponent = self
  }

  func displayMessage(_ messageForDisplay: InAppMessagingDisplayMessage,
                      displayDelegate: InAppMessagingDisplayDelegate) {
    DispatchQueue.main.async {
      self.inAppMessage = messageForDisplay
    }
  }
}

public extension View {
  func onInAppMessage<T: View>(closure: @escaping (InAppMessagingDisplayMessage) -> T) -> some View {
    modifier(InAppMessagingDisplayModifier(closure: closure))
  }
}
