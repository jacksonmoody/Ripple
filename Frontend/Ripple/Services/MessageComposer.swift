import MessageUI
import SwiftUI

struct MessageComposerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var recipients: [String]
    var messageBody: String
    var onResult: (MessageComposeResult, [String]) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = messageBody
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposerView

        init(_ parent: MessageComposerView) {
            self.parent = parent
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            let finalRecipients = controller.recipients ?? []
            parent.onResult(result, finalRecipients)
            parent.isPresented = false
            controller.dismiss(animated: true)
        }
    }
}
