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
    
    private let phoneUtil = NBPhoneNumberUtil.sharedInstance()
    private let countries: [CountryInfo]
    
    init(phoneNumber: Binding<String>, isValid: Binding<Bool>) {
        self._phoneNumber = phoneNumber
        self._isValid = isValid
        
        let (countryList, defaultCountry) = Self.initializeCountries()
        self.countries = countryList
        self._selectedCountry = State(initialValue: defaultCountry)
    }
    
    private static func initializeCountries() -> ([CountryInfo], CountryInfo) {
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
        return (countryList, defaultCountry)
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("Country", selection: $selectedCountry) {
                    ForEach(countries, id: \.code) { country in
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
                    .onChange(of: localPhoneNumber) { _, _ in
                        validatePhoneNumber()
                    }
            }
            
            if !isValid && !localPhoneNumber.isEmpty {
                Text("Invalid phone number")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .onChange(of: selectedCountry) { _, _ in
            validatePhoneNumber()
        }
        .onAppear {
            parseInitialPhoneNumber()
        }
    }
    
    private func parseInitialPhoneNumber() {
        do {
            if let parsedNumber = try phoneUtil?.parse(phoneNumber, defaultRegion: nil) {
                if let countryCode = parsedNumber.countryCode?.stringValue,
                   let country = countries.first(where: { $0.prefix == countryCode }) {
                    selectedCountry = country
                }
                localPhoneNumber = try phoneUtil?.format(parsedNumber, numberFormat: .NATIONAL) ?? phoneNumber
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
        guard let phoneUtil = phoneUtil else {
            isValid = false
            return
        }
        
        do {
            let fullNumber = "+\(selectedCountry.prefix)\(localPhoneNumber)"
            let parsedNumber = try phoneUtil.parse(fullNumber, defaultRegion: selectedCountry.code)
            isValid = phoneUtil.isValidNumber(parsedNumber)
            if isValid {
                phoneNumber = try phoneUtil.format(parsedNumber, numberFormat: .E164)
                localPhoneNumber = try phoneUtil.format(parsedNumber, numberFormat: .NATIONAL)
                
                // Update selectedCountry based on the parsed number
                if let countryCode = parsedNumber.countryCode?.stringValue,
                   let country = countries.first(where: { $0.prefix == countryCode }) {
                    selectedCountry = country
                }
            } else {
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
