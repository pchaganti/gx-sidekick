//
//  InputFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/18/25.
//

import AppKit
import Foundation

public class InputFunctions {
    
    static var functions: [AnyFunctionBox] = [
        InputFunctions.getConfirmation,
        InputFunctions.getTextInput
    ]
    
    /// A ``Function`` to ask for confirmation
    static let getConfirmation = Function<GetConfirmationParams, String>(
        name: "get_confirmation",
        description: "Get user confirmation to clarify user intent by presenting a dialog with a title and message, where the user can click `Yes` or `No. ONLY returns `Yes` or `No`.",
        params: [
            FunctionParameter(
                label: "title",
                description: "The title displayed in the alert",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "message",
                description: "The message displayed in the alert. This should end with a yes or no question such as `Do you want to continue?`.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            let dialogResult: Bool = Dialogs.showConfirmation(
                title: params.title,
                message: params.message
            )
            return """
An confirmation dialog with the message \"\(params.message)\" was shown.

The user responded by clicking \(dialogResult ? "Yes" : "No").
"""
        }
    )
    struct GetConfirmationParams: FunctionParams {
        let title: String
        let message: String
    }
    
    /// A ``Function`` to ask for text input
    static let getTextInput = Function<GetTextInputParams, String>(
        name: "get_text_input",
        description: "Displays a prompt asking for text input from the user. Returns the text input from the user.",
        params: [
            FunctionParameter(
                label: "title",
                description: "The title displayed in the prompt.",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "message",
                description: "The message displayed in the prompt. Use this to ask the user for input.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Put together alert
            let alert = NSAlert()
            alert.messageText = params.title
            alert.informativeText = params.message
            alert.alertStyle = .informational
            // Configure elements
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            textField.bezelStyle = .roundedBezel
            alert.accessoryView = textField
            alert.addButton(withTitle: "Done")
            alert.addButton(withTitle: "Cancel")
            // Ask user
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                return textField.stringValue
            } else {
                throw TextInputError.declined
            }
            enum TextInputError: LocalizedError {
                case declined
                var errorDescription: String? {
                    switch self {
                        case .declined:
                            return "The user declined the request."
                    }
                }
            }
        }
    )
    struct GetTextInputParams: FunctionParams {
        let title: String
        let message: String
    }
    
}
