//
//  WebLinksView.swift
//  Helix
//
//  Created by Richard Waithe on 10/12/24.
//

import SwiftUI

struct WebLinksView: View {
    @Binding var businessCard: BusinessCard
    @State private var linkInputs: [WebLink] = []
    @FocusState private var focusedField: Field?
    var showHeader: Bool
    @State private var offsets: [CGFloat] = []

    init(businessCard: Binding<BusinessCard>, showHeader: Bool = true) {
        self._businessCard = businessCard
        self.showHeader = showHeader
    }
    
    enum Field: Hashable {
        case url(Int)
        case displayText(Int)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showHeader {
                Text("Web Links")
                    .font(.headline)
                    .padding(.bottom, 16)
            }
            
            ForEach(linkInputs.indices, id: \.self) { index in
                ZStack {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Spacer()
                            Button(action: { removeLink(at: index) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            }
                            .frame(width: 60, height: geometry.size.height)
                            .offset(x: offsets[index] + 60)
                        }
                        .frame(height: geometry.size.height, alignment: .center)
                    }
                    
                    HStack(alignment: .top) {
                        VStack(spacing: 10) {
                            CustomTextField(title: "Link", text: Binding(
                                get: { linkInputs[index].url },
                                set: { newValue in
                                    linkInputs[index].url = addProtocolToUrl(newValue)
                                }
                            ), onCommit: { focusedField = .displayText(index) })
                                .focused($focusedField, equals: .url(index))
                                .animation(.none, value: linkInputs[index].url)
                            CustomTextField(title: "Display Text (optional)", text: $linkInputs[index].displayText, onCommit: {
                                if index < linkInputs.count - 1 {
                                    focusedField = .url(index + 1)
                                } else {
                                    focusedField = nil
                                }
                            })
                            .focused($focusedField, equals: .displayText(index))
                            .animation(.none, value: linkInputs[index].displayText)
                        }
                        .layoutPriority(1)
                    }
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .offset(x: offsets[index])
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onChanged { gesture in
                                if abs(gesture.translation.width) > abs(gesture.translation.height) {
                                    offsets[index] = min(0, gesture.translation.width)
                                }
                            }
                            .onEnded { gesture in
                                withAnimation {
                                    if gesture.translation.width < -50 && abs(gesture.translation.width) > abs(gesture.translation.height) {
                                        offsets[index] = -60
                                    } else {
                                        offsets[index] = 0
                                    }
                                }
                            }
                    )
                }
                
                Divider()
                    .padding(.top, 10)
            }
            
            Button(action: addNewLinkInput) {
                Text("Add Another Link")
                    .foregroundColor(AppColors.buttonText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.buttonBackground)
                    .cornerRadius(16)
            }

        }
        .padding(.top, showHeader ? 0 : 16)
        .animation(.none)
        .onAppear(perform: loadExistingLinks)
        .onChange(of: linkInputs) { _ in
            updateBusinessCard()
            updateOffsets()
        }
    }
    
    private func loadExistingLinks() {
        linkInputs = businessCard.webLinks ?? []
        if linkInputs.isEmpty {
            linkInputs.append(WebLink(url: "", displayText: ""))
        }
        updateOffsets()
    }
    
    private func addNewLinkInput() {
        linkInputs.append(WebLink(url: "", displayText: ""))
        offsets.append(0)
        focusedField = .url(linkInputs.count - 1)
    }
    
    private func removeLink(at index: Int) {
        linkInputs.remove(at: index)
        offsets.remove(at: index)
        updateBusinessCard()
    }
    
    private func updateOffsets() {
        while offsets.count < linkInputs.count {
            offsets.append(0)
        }
        while offsets.count > linkInputs.count {
            offsets.removeLast()
        }
    }
    
    private func updateBusinessCard() {
        businessCard.webLinks = linkInputs.filter { !$0.url.isEmpty && $0.url != "http://" && $0.url != "https://" }
            .map { WebLink(url: addProtocolToUrl($0.url), displayText: $0.displayText) }
    }

    private func addProtocolToUrl(_ url: String) -> String {
        if url.isEmpty || url == "http://" || url == "https://" {
            return ""
        }
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        }
        return "https://" + url
    }
}
