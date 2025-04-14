//
//  DefaultFunctions.swift
//  Sidekick
//
//  Created by John Bean on 4/7/25.
//

import AppKit
import Contacts
import Foundation
import FSKit_macOS

public protocol FunctionParams: Codable, Hashable {}

public class DefaultFunctions {
    
    static var functions: [AnyFunctionBox] = [
        ArithmeticFunctions.functions,
        FileFunctions.functions,
        CodeFunctions.functions,
        [
            DefaultFunctions.showAlert,
            DefaultFunctions.webSearch,
            DefaultFunctions.draftEmail,
            DefaultFunctions.fetchContacts
        ]
    ].flatMap { $0 }
    
    /// A ``Function`` to show alerts
    static let showAlert = Function<ShowAlertParams, String?>(
        name: "show_alert",
        description: "Show an alert dialog to the user",
        params: [
            FunctionParameter(
                label: "message",
                description: "The message displayed in the alert",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            DispatchQueue.main.async {
                Dialogs.showAlert(
                    title: "Alert",
                    message: params.message
                )
            }
            return "An alert with the message \"\(params.message)\" was shown."
        }
    )
    struct ShowAlertParams: FunctionParams {
        let message: String
    }
    
    /// A ``Function`` to conduct a web search
    static let webSearch = Function<WebSearchParams, String>(
        name: "web_search",
        description: "Retrieves information from the web with the provided query, instead of estimating it.",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "query",
                description: "The topic to look up online",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { param in
            // Check if enabled
            if !RetrievalSettings.canUseWebSearch {
                throw WebSearchError.notEnabled
            }
            // Conduct search
            let sources: [Source] = try await TavilySearch.search(
                query: param.query,
                resultCount: 3
            )
            // Convert to JSON
            let sourcesInfo: [Source.SourceInfo] = sources.map(\.info)
            let jsonEncoder: JSONEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted]
            let jsonData: Data = try! jsonEncoder.encode(sourcesInfo)
            let resultsText: String = String(
                data: jsonData,
                encoding: .utf8
            )!
            return resultsText
            // Custom error for Web Search function
            enum WebSearchError: Error {
                case notEnabled
                var localizedDescription: String {
                    switch self {
                        case .notEnabled:
                            return "Web search has not been enabled in Settings."
                    }
                }
            }
        }
    )
    struct WebSearchParams: FunctionParams {
        let query: String
    }
    
    /// A function to create an email draft
    static let draftEmail = Function<DraftEmailParams, String>(
        name: "draft_email",
        description: "Uses the \"mailto:\" URL scheme to create an email draft in the default email client.",
        clearance: .sensitive,
        params: [
            FunctionParameter(
                label: "recipients",
                description: "An array containing the email addresses of the recipients.",
                datatype: .stringArray,
                isRequired: true
            ),
            FunctionParameter(
                label: "cc",
                description: "An array containing the email addresses of the cc recipients.",
                datatype: .stringArray,
                isRequired: true
            ),
            FunctionParameter(
                label: "bcc",
                description: "An array containing the email addresses of the cc recipients.",
                datatype: .stringArray,
                isRequired: true
            ),
            FunctionParameter(
                label: "subject",
                description: "The subject of the email",
                datatype: .string,
                isRequired: true
            ),
            FunctionParameter(
                label: "body",
                description: "The body of the email.",
                datatype: .string,
                isRequired: true
            )
        ],
        run: { params in
            // Formulate URL
            var urlString: String = "mailto:"
            urlString += params.recipients.joined(separator: ",")
            // Start query parameters
            var queryItems: [String] = []
            // Add CC & BCC recipients if present
            if let cc = params.cc, !cc.isEmpty {
                queryItems.append("cc=\(cc.joined(separator: ","))")
            }
            if let bcc = params.bcc, !bcc.isEmpty {
                queryItems.append("bcc=\(bcc.joined(separator: ","))")
            }
            // Add subject & body
            if !params.subject.isEmpty {
                queryItems.append("subject=\(params.subject)")
            }
            if !params.body.isEmpty {
                queryItems.append("body=\(params.body)")
            }
            // Append query parameters if there are any
            if !queryItems.isEmpty {
                urlString += "?" + queryItems.joined(separator: "&")
            }
            // URL encode the string
            guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                throw DraftEmailError.percentEncodingFailed
            }
            // Formulate and open URL
            guard let url: URL = URL(string: encodedString) else {
                throw DraftEmailError.urlCreationFailed
            }
            let _ = NSWorkspace.shared.open(url)
            return "Successfully created email draft"
            enum DraftEmailError: Error {
                
                case percentEncodingFailed
                case urlCreationFailed
                
                var localizedDescription: String {
                    switch self {
                        case .percentEncodingFailed:
                            return "Failed to add percent encoding to `mailto` URL"
                        case .urlCreationFailed:
                            return "Failed to create URL from `mailto` string"
                    }
                }
            }
        }
    )
    struct DraftEmailParams: FunctionParams {
        let recipients: [String]
        let cc: [String]?
        let bcc: [String]?
        let subject: String
        let body: String
    }
    
    /// A function to get all contacts
    static let fetchContacts = Function<FetchContactsParams, String>(
        name: "fetch_contacts",
        description: """
Fetches contacts from macOS Contacts. The user's contact can be accessed to obtain their email, birthday, address, etc.

Returns JSON objects for each contact containing the person's name, emails, phone numbers, birthday (as string), and address. Supports filtering based on name, email, and phone number.
""",
        clearance: .dangerous,
        params: [
            FunctionParameter(
                label: "name",
                description: "Filter for contacts with a name containing this string. (optional)",
                datatype: .string,
                isRequired: false
            ),
            FunctionParameter(
                label: "email",
                description: "Filter for contacts with this email. (optional)",
                datatype: .string,
                isRequired: false
            ),
            FunctionParameter(
                label: "phone",
                description: "Filter for contacts with this phone number. (optional)",
                datatype: .string,
                isRequired: false
            )
        ],
        run: { params in
            return try await { () -> String in
                struct Contact: Codable {
                    let name: String
                    let emails: [String]
                    let phoneNumbers: [String]
                    let birthday: String?
                    let address: [String]
                }
                // Get contacts
                let store = CNContactStore()
                // Request access to contacts
                let accessGranted = try await CNContactStore.requestContactsAccess(using: store)
                guard accessGranted else {
                    throw ContactError.accessDenied
                }
                // Define the keys we want to fetch
                let keys: [CNKeyDescriptor] = [
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactFamilyNameKey as CNKeyDescriptor,
                    CNContactEmailAddressesKey as CNKeyDescriptor,
                    CNContactPhoneNumbersKey as CNKeyDescriptor,
                    CNContactPostalAddressesKey as CNKeyDescriptor,
                    CNContactBirthdayKey as CNKeyDescriptor
                ]
                // Create a fetch request for contacts
                let request = CNContactFetchRequest(keysToFetch: keys)
                var contactsList: [CNContact] = []
                try store.enumerateContacts(with: request) { contact, _ in
                    contactsList.append(contact)
                }
                // Apply filtering if filters are provided
                if let nameFilter = params.name, !nameFilter.isEmpty {
                    contactsList = contactsList.filter { contact in
                        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                        return fullName.localizedCaseInsensitiveContains(nameFilter)
                    }
                }
                if let emailFilter = params.email, !emailFilter.isEmpty {
                    contactsList = contactsList.filter { contact in
                        contact.emailAddresses.contains { email in
                            let emailString = email.value as String
                            return emailString.localizedCaseInsensitiveContains(emailFilter)
                        }
                    }
                }
                if let phoneFilter = params.phone, !phoneFilter.isEmpty {
                    contactsList = contactsList.filter { contact in
                        contact.phoneNumbers.contains { phone in
                            let phoneString = phone.value.stringValue
                            return phoneString.localizedCaseInsensitiveContains(phoneFilter)
                        }
                    }
                }
                // Check if any contacts remain after filtering
                guard !contactsList.isEmpty else {
                    throw ContactError.noContactsFound
                }
                // Map each CNContact to a Contact instance
                let mappedContacts = contactsList.map { contact -> Contact in
                    let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                    let emails = contact.emailAddresses.map { $0.value as String }
                    let phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
                    // Format birthday as a string
                    var birthdayString: String? = nil
                    if let birthday = contact.birthday, birthday.month != nil, birthday.day != nil {
                        birthdayString = birthday.date?.dateString
                    }
                    let addresses = contact.postalAddresses.map { postal in
                        let addr = postal.value
                        return "\(addr.street), \(addr.city), \(addr.state), \(addr.postalCode), \(addr.country)"
                    }
                    return Contact(name: fullName, emails: emails, phoneNumbers: phoneNumbers, birthday: birthdayString, address: addresses)
                }
                // Encode the contacts array to JSON
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted]
                guard let jsonData = try? encoder.encode(mappedContacts),
                      let jsonString = String(data: jsonData, encoding: .utf8) else {
                    throw ContactError.jsonEncodingFailed
                }
                return jsonString
                // Error enum
                enum ContactError: Error, LocalizedError {
                    
                    case accessDenied
                    case noContactsFound
                    case jsonEncodingFailed
                    
                    var errorDescription: String? {
                        switch self {
                            case .accessDenied:
                                return "Access to contacts was denied."
                            case .noContactsFound:
                                return "No contacts remain after filtering."
                            case .jsonEncodingFailed:
                                return "Failed to encode contacts to JSON."
                        }
                    }
                }
            }()
        }
    )
    struct FetchContactsParams: FunctionParams {
        var name: String?
        var email: String?
        var phone: String?
    }
    
}
