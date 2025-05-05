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
        CalendarFunctions.functions,
        CodeFunctions.functions,
        FileFunctions.functions,
        InputFunctions.functions,
        RemindersFunctions.functions,
        WebFunctions.functions,
        [
            DefaultFunctions.fetchContacts
        ]
    ].flatMap { $0 }
    
    static var sortedFunctions: [AnyFunctionBox] {
        return DefaultFunctions.functions.sorted(
            by: \.params.count,
            order: .reverse
        )
    }
    
    /// A function to get all contacts
    static let fetchContacts = Function<FetchContactsParams, String>(
        name: "fetch_contacts",
        description: """
Fetches contacts from macOS Contacts. The user's contact can be accessed to obtain their email, birthday, address, etc.

Returns JSON objects for each contact containing the person's name, emails, phone numbers, birthday, and address. Supports filtering based on name, email, and phone number.
""",
        clearance: .sensitive,
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
