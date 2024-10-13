//
//  ContactInformationView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI
import PhoneNumberKit

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
                .onChange(of: email) { newValue in
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
    
    private let phoneNumberKit = PhoneNumberKit()
    private let countries: [CountryInfo]
    
    init(phoneNumber: Binding<String>, isValid: Binding<Bool>) {
        self._phoneNumber = phoneNumber
        self._isValid = isValid
        
        let allCountries = phoneNumberKit.allCountries().compactMap { code -> CountryInfo? in
            guard let name = phoneNumberKit.countryName(for: code),
                  let prefix = phoneNumberKit.countryCode(for: code) else {
                return nil
            }
            return CountryInfo(code: code, name: name, prefix: prefix)
        }.sorted { $0.name < $1.name }
        
        self.countries = allCountries
        self._selectedCountry = State(initialValue: allCountries.first(where: { $0.code == "US" }) ?? allCountries[0])
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker("Country", selection: $selectedCountry) {
                    ForEach(countries, id: \.code) { country in
                        Text("\(country.flag) \(country.name) (+\(country.prefix))")
                            .tag(country)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
                .background(Color.white)
                .cornerRadius(8)
                
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .onChange(of: phoneNumber) { _ in
                        validatePhoneNumber()
                    }
            }
            
            if !isValid && !phoneNumber.isEmpty {
                Text("Invalid phone number")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private func validatePhoneNumber() {
        do {
            let fullNumber = "+\(selectedCountry.prefix)\(phoneNumber)"
            let parsedNumber = try phoneNumberKit.parse(fullNumber)
            phoneNumber = phoneNumberKit.format(parsedNumber, toType: .international)
            isValid = true
        } catch {
            isValid = false
        }
    }
}

struct CountryInfo: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let prefix: UInt64
    
    var flag: String {
        String(String.UnicodeScalarView(
            code.unicodeScalars.compactMap {
                UnicodeScalar(127397 + $0.value)
            }
        ))
    }
}
