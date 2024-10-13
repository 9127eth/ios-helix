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
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var isPhoneNumberValid = false
    @State private var isEmailValid = false
    
    var body: some View {
        VStack(spacing: 20) {
            PhoneNumberTextField(phoneNumber: $phoneNumber, isValid: $isPhoneNumberValid)
            
            CustomTextField(title: "Email", text: $email)
                .onChange(of: email) { _, newValue in
                    isEmailValid = isValidEmail(newValue)
                }
            
            Button("Save") {
                if isPhoneNumberValid && isEmailValid {
                    businessCard.phoneNumber = phoneNumber
                    businessCard.email = email
                    // Additional save logic here
                }
            }
            .disabled(!isPhoneNumberValid || !isEmailValid)
        }
        .onAppear {
            phoneNumber = businessCard.phoneNumber ?? ""
            email = businessCard.email ?? ""
        }
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
        VStack {
            HStack {
                Picker("Country", selection: $selectedCountry) {
                    ForEach(countries) { country in
                        Text("\(country.flag) +\(country.prefix)")
                            .tag(country)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
                .background(Color.white)
                .cornerRadius(8)
                
                TextField("Phone Number", text: $localPhoneNumber)
                    .keyboardType(.phonePad)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
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
                // Use INTERNATIONAL format to include country code
                localPhoneNumber = try Self.phoneUtil?.format(parsedNumber, numberFormat: .INTERNATIONAL) ?? phoneNumber
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
            // Use the full number input by the user
            let fullNumber = localPhoneNumber
            let parsedNumber = try phoneUtil.parse(fullNumber, defaultRegion: selectedCountry.code)
            
            // Use isPossibleNumber instead of isValidNumber
            isValid = phoneUtil.isPossibleNumber(parsedNumber)
            if isValid {
                // Format the number to E164 for storage
                phoneNumber = try phoneUtil.format(parsedNumber, numberFormat: .E164)
                
                // Optionally, format it to INTERNATIONAL for display
                localPhoneNumber = try phoneUtil.format(parsedNumber, numberFormat: .INTERNATIONAL)
                
                // Ensure selectedCountry remains the same
            } else {
                // Keep the user's input as is
                phoneNumber = fullNumber
            }
        } catch {
            isValid = false
            phoneNumber = localPhoneNumber
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
