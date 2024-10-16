//
//  ContactInformationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI
import libPhoneNumber

struct ContactInformationView: View {
    @Binding var businessCard: BusinessCard
    @State private var isPhoneNumberValid = false
    @State private var isEmailValid = true
    @State private var showEmailError = false
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    
    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    enum Field: Hashable {
        case phoneNumber, email
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Contact Information")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            PhoneNumberTextField(phoneNumber: Binding(
                get: { businessCard.phoneNumber ?? "" },
                set: { businessCard.phoneNumber = $0.isEmpty ? nil : $0 }
            ), isValid: $isPhoneNumberValid)
                .focused($focusedField, equals: .phoneNumber)
                .onSubmit { focusedField = .email }
            
            CustomTextField(title: "Email", text: Binding(
                get: { businessCard.email ?? "" },
                set: { businessCard.email = $0.isEmpty ? nil : $0 }
            ))
                .focused($focusedField, equals: .email)
                .keyboardType(.emailAddress)
                .onSubmit { focusedField = nil }
                .onChange(of: businessCard.email) { newValue in
                    if let email = newValue, !email.isEmpty {
                        isEmailValid = isValidEmail(email)
                        showEmailError = !isEmailValid
                    } else {
                        isEmailValid = true
                        showEmailError = false
                    }
                }
            
            if showEmailError {
                Text("Invalid email format")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.top, showHeader ? 0 : 16)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct PhoneNumberTextField: View {
    @Binding var phoneNumber: String
    @Binding var isValid: Bool
    @State private var selectedCountry: CountryInfo
    @State private var localPhoneNumber: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    private static let phoneUtil = NBPhoneNumberUtil.sharedInstance()
    private static let countriesData = initializeCountries()
    private let countries: [CountryInfo] = Self.countriesData.countries
    private let defaultCountry: CountryInfo = Self.countriesData.defaultCountry
    
    init(phoneNumber: Binding<String>, isValid: Binding<Bool>) {
        self._phoneNumber = phoneNumber
        self._isValid = isValid
        self._selectedCountry = State(initialValue: defaultCountry)
    }
    
    private static func initializeCountries() -> (countries: [CountryInfo], defaultCountry: CountryInfo) {
        let phoneUtil = NBPhoneNumberUtil.sharedInstance()
        let allRegions = Locale.isoRegionCodes
        let countryList = allRegions.compactMap { regionCode -> CountryInfo? in
            guard let name = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: regionCode),
                  let code = phoneUtil?.getCountryCode(forRegion: regionCode) else {
                return nil
            }
            return CountryInfo(code: regionCode, name: name, prefix: code.stringValue)
        }.sorted { $0.name < $1.name }
        
        let defaultCountry = countryList.first(where: { $0.code == "US" }) ?? countryList[0]
        return (countries: countryList, defaultCountry: defaultCountry)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mobile Number")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            HStack(spacing: 8) {
                Menu {
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries) { country in
                            Text("\(country.flag) +\(country.prefix) \(country.name)")
                                .tag(country)
                        }
                    }
                } label: {
                    Text(selectedCountry.flag)
                        .frame(width: 40, height: 40)
                        .background(AppColors.inputFieldBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }

                TextField("Phone Number", text: $localPhoneNumber)
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(AppColors.inputFieldBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .onChange(of: localPhoneNumber) { _ in
                        validatePhoneNumber()
                    }
            }

            if !isValid && !localPhoneNumber.isEmpty {
                Text("Invalid phone number format")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .onChange(of: selectedCountry) { _ in
            validatePhoneNumber()
        }
        .onAppear {
            parseInitialPhoneNumber()
        }
    }
    
    private func parseInitialPhoneNumber() {
        do {
            if let parsedNumber = try Self.phoneUtil?.parse(phoneNumber, defaultRegion: selectedCountry.code) {
                // Format the number without country code for display
                localPhoneNumber = try Self.phoneUtil?.format(parsedNumber, numberFormat: .NATIONAL) ?? phoneNumber
                validatePhoneNumber() // Ensure isValid is set correctly
            } else {
                localPhoneNumber = phoneNumber
            }
        } catch {
            localPhoneNumber = phoneNumber
            print("Error parsing initial phone number: \(error)")
        }
    }
    
    private func validatePhoneNumber() {
        guard let phoneUtil = Self.phoneUtil else {
            isValid = false
            return
        }
        
        do {
            // Prepend the country code to the local number for parsing
            let fullNumber = "+\(selectedCountry.prefix)\(localPhoneNumber)"
            let parsedNumber = try phoneUtil.parse(fullNumber, defaultRegion: selectedCountry.code)
            
            isValid = phoneUtil.isPossibleNumber(parsedNumber)
            if isValid {
                // Format the number to E164 for storage
                phoneNumber = try phoneUtil.format(parsedNumber, numberFormat: .E164)
                
                // Format the number without country code for display
                localPhoneNumber = try phoneUtil.format(parsedNumber, numberFormat: .NATIONAL)
            } else {
                // Keep the user's input as is
                phoneNumber = fullNumber
            }
        } catch {
            isValid = false
            phoneNumber = "+\(selectedCountry.prefix)\(localPhoneNumber)"
            print("Error validating phone number: \(error)")
        }
    }
}

struct CountryInfo: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let prefix: String
    
    var flag: String {
        String(String.UnicodeScalarView(
            code.unicodeScalars.compactMap {
                UnicodeScalar(127397 + $0.value)
            }
        ))
    }
}
