import FirebaseInAppMessaging
import SwiftUI

// Handle delegate for FIAM actions.
struct InAppMessagingDisplayModifier<DisplayMessage: View>: ViewModifier {
  var closure: (InAppMessagingDisplayMessage, InAppMessagingDisplayDelegate) -> DisplayMessage

  @ObservedObject var delegateBridge: DelegateBridge = DelegateBridge()

  init(closure: @escaping (InAppMessagingDisplayMessage, InAppMessagingDisplayDelegate)
    -> DisplayMessage) {
    self.closure = closure
  }

  func body(content: Content) -> some View {
    let inAppMessage = delegateBridge.inAppMessage
    return content
      .overlay(inAppMessage == nil ? AnyView(EmptyView()) :
        AnyView(closure(inAppMessage!.0, inAppMessage!.1)))
  }
}

class DelegateBridge: NSObject, InAppMessagingDisplay, InAppMessagingDisplayDelegate,
  ObservableObject {
  @Published var inAppMessage: (InAppMessagingDisplayMessage, InAppMessagingDisplayDelegate)? = nil

  override init() {
    super.init()
    InAppMessaging.inAppMessaging().messageDisplayComponent = self
    InAppMessaging.inAppMessaging().delegate = self
  }

  func displayMessage(_ messageForDisplay: InAppMessagingDisplayMessage,
                      displayDelegate: InAppMessagingDisplayDelegate) {
    DispatchQueue.main.async {
      self.inAppMessage = (messageForDisplay, displayDelegate)
    }
  }

  func messageClicked(_ inAppMessage: InAppMessagingDisplayMessage,
                      with action: InAppMessagingAction) {
    self.inAppMessage = nil
  }

  func messageDismissed(_ inAppMessage: InAppMessagingDisplayMessage,
                        dismissType: FIRInAppMessagingDismissType) {
    self.inAppMessage = nil
  }
}

// View modifier that takes a closure for handling in-app message display.
public extension View {
  func onDisplayInAppMessage<T: View>(closure: @escaping (InAppMessagingDisplayMessage,
                                                          InAppMessagingDisplayDelegate) -> T)
    -> some View {
    modifier(InAppMessagingDisplayModifier(closure: closure))
  }
}
