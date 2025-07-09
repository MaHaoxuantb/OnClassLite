//
//  SettingsView.swift
//  SuperLearn -> ClassOn
//
//  Created by Thomas B on 5/15/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("InDebugMode") var InDebugMode: Bool = true
    @AppStorage("UseBackgroundImages") var UseBackgroundImages: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Profile")) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                        VStack {
                            Text("UserName:")
                                .font(.subheadline)
                                .padding(2)
                            Text("ThomasB(TestAdmin)")
                                .font(.headline)
                                .padding(3)
                        }
                        .background(
                            Color.gray.opacity(0.3)
                                .blur(radius: 40)
                        )
                    }
                }
                Section(header: Text("App")) {
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
                    NavigationLink(destination: ThirdPartiesView()) {
                        Text("Third Party Usages")
                    }
                    NavigationLink(destination: LicenseView()) {
                        Text("App Licenses")
                    }
                }
                if InDebugMode {
                    Section(header: Text("Debug Only")) {
                        Toggle(isOn: $UseBackgroundImages) {
                            Text("Use background images")
                        }
                    }
                }
            }
        }
        .background(.regularMaterial)
    }
}

struct LicenseView: View {
    var body: some View{
        List {
            NavigationLink(destination: WebView(url: URL(string: "https://redirect.thomasb.top/?domain=license.mahaoxuan.top&path=UserAgreement.html&originService=ConiWords1")!)) {
                Text("General User Agreements")
            }
            NavigationLink(destination: WebView(url: URL(string: "https://redirect.thomasb.top/?domain=license.mahaoxuan.top&path=PrivacyPolicy.html&originService=ConiWords1")!)) {
                Text("General Privacy Policies")
            }
            NavigationLink(destination: WebView(url: URL(string: "https://redirect.thomasb.top/?domain=license.mahaoxuan.top&path=ConiWords/ConiWords_UserAgreements_EN.html&originService=ConiWords1")!)) {
                Text("APP User Agreements")
            }
        }
        .navigationTitle("App Licenses")
    }
}

//about this app VIEW
struct AboutView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 68)
                        .blur(radius: 80)
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer().frame(height: 190)
                    HStack {
                        VStack {
                            Spacer()
                                .frame(height: 4)
                            Text("LinecoFlow")
                                .font(.title3)
                                .bold()
                                .background(
                                    Color.gray.opacity(0.8)
                                        .blur(radius: 32)
                                )
                                .padding([.top, .leading, .bottom], 5)
                        }
                        Text("ClassOn")
                            .font(.title)
                            .bold()
                            .background(
                                Color.gray.opacity(0.8)
                                    .blur(radius: 32)
                            )
                            .padding([.top, .bottom, .trailing], 5)
                    }
                    Text("Version 0.3")
                        .font(.subheadline)
                        .padding()
                    Spacer().frame(height: 60)
                    Text("App Builder:")
                        .padding(2)
                    Text("ThomasB @ LinecoFlow")
                        .bold()
                        .padding(2)
                    Spacer()
                    Text("©2025 LinecoFlow Tech Co.,")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(0.3)
                    Text("All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(0.3)
                    Text("A ThomasB Internet Services Company")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(0.3)
                    Spacer().frame(height: 8)
                }
            }
        }
        .navigationTitle("About")
    }
}

//third parties VIEW
struct ThirdPartiesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Open Source")) {
                    NavigationLink(destination: WebView(url: URL(string: "https://github.com/gonzalezreal/swift-markdown-ui")!)) {
                        Text("swift-markdown-ui")
                    }
                }
                
                Section(header: Text("Commercial")) {
                }
            }
            
            VStack(alignment: .center) {
                Image(systemName: "questionmark.app")
                    .padding(1)
                Text("Open Source")
                    .font(.footnote)
                    .padding(0.2)
                Text("We thanks for their contribution to this whole world.")
                    .font(.footnote)
                    .padding(0.2)
            }
            .padding(.horizontal, 5)
        }
        .navigationTitle("Third Party Usages")
    }
}

#Preview {
    SettingsView()
}
