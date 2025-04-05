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
    @State private var isEmailValid = true
    @State private var showEmailError = false
    @State private var showPhoneNumberError = false
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    @Binding var isPhoneNumberValid: Bool
    
    init(businessCard: Binding<BusinessCard>, 
         showHeader: Bool = true,
         isPhoneNumberValid: Binding<Bool> = .constant(true)) {
        self._businessCard = businessCard
        self.showHeader = showHeader
        self._isPhoneNumberValid = isPhoneNumberValid
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
                set: { 
                    let newValue = $0.isEmpty ? nil : $0
                    businessCard.phoneNumber = newValue
                    if newValue == nil {
                        isPhoneNumberValid = true
                        showPhoneNumberError = false
                    }
                }
            ), isValid: $isPhoneNumberValid, showError: $showPhoneNumberError)
                .focused($focusedField, equals: .phoneNumber)
                .onSubmit {
                    if !isPhoneNumberValid {
                        showPhoneNumberError = true
                    } else {
                        showPhoneNumberError = false
                        focusedField = .email
                    }
                }
            
            if businessCard.phoneNumber?.isEmpty == false {
                Toggle("Enable \"Send a Text\" button", isOn: Binding(
                    get: { businessCard.enableTextMessage ?? true },
                    set: { businessCard.enableTextMessage = $0 }
                ))
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 4)
                .padding(.horizontal, 16)
            }
            
            CustomTextField(title: "Email", text: Binding(
                get: { businessCard.email ?? "" },
                set: { businessCard.email = $0.isEmpty ? nil : $0 }
            ))
                .focused($focusedField, equals: .email)
                .keyboardType(.emailAddress)
                .onSubmit { focusedField = nil }
                .onChange(of: businessCard.email) { oldValue, newValue in
                    if let email = newValue, !email.isEmpty {
                        isEmailValid = isValidEmail(email)
                    } else {
                        isEmailValid = true
                    }
                }
            
            if showEmailError && !isEmailValid {
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
    @Binding var showError: Bool
    @State private var selectedCountry: CountryInfo
    @State private var localPhoneNumber = ""
    @Environment(\.colorScheme) var colorScheme
    
    private static let phoneUtil = NBPhoneNumberUtil.sharedInstance()
    private static let countriesData = initializeCountries()
    private let countries: [CountryInfo] = Self.countriesData.countries
    private let defaultCountry: CountryInfo = Self.countriesData.defaultCountry
    
    init(phoneNumber: Binding<String>, isValid: Binding<Bool>, showError: Binding<Bool>) {
        self._phoneNumber = phoneNumber
        self._isValid = isValid
        self._showError = showError
        self._selectedCountry = State(initialValue: defaultCountry)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Phone Number")
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
                    .onChange(of: localPhoneNumber) { oldValue, newValue in
                        validatePhoneNumber()
                    }
            }

            if !isValid && !localPhoneNumber.isEmpty && showError {
                Text("Invalid phone number format")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .onChange(of: selectedCountry) { oldValue, newValue in
            validatePhoneNumber()
        }
        .onAppear {
            parseInitialPhoneNumber()
        }
    }
    
    private static func initializeCountries() -> (countries: [CountryInfo], defaultCountry: CountryInfo) {
        let phoneUtil = NBPhoneNumberUtil.sharedInstance()
        let allRegions = Locale.Region.isoRegions.map(\.identifier)
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
        // If phone number is empty, consider it valid and reset binding
        if localPhoneNumber.isEmpty {
            isValid = true
            phoneNumber = ""
            return
        }
        
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
