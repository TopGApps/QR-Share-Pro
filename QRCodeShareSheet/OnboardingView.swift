//
//  OnboardingView.swift
//  QRCodeShareSheet
//
//  Created by Aaron Ma on 3/5/24.
//

import SwiftUI

struct OnboardingPageView: View {
    var image: Image
    var title: String
    var description: String
    
    var body: some View {
        VStack {
            image
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding(.top, 50)
                .padding(.bottom, 50)
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .padding(.bottom, 50)
            Spacer()
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var qrCodeStore: QRCodeStore
    @EnvironmentObject var storeKit: StoreKitManager
    
    @AppStorage("isOnboardingDone") private var isOnboardingDone = false
    
    @State private var selection: Tab = .Home
    
    enum Tab {
        case Scanner
        case Home
        case History
    }
    
    var body: some View {
        if isOnboardingDone {
            TabView(selection: $selection) {
                Scanner()
                    .tabItem {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }
                    .onAppear {
                        Task {
                            try await qrCodeStore.load()
                        }
                    }
                    .tag(Tab.Scanner)
                
                Home()
                    .environmentObject(qrCodeStore)
                    .environmentObject(storeKit)
                    .tabItem {
                        Label("New QR Code", systemImage: "qrcode")
                    }
                    .onAppear {
                        Task {
                            try await qrCodeStore.load()
                        }
                    }
                    .tag(Tab.Home)
                
                History()
                    .environmentObject(qrCodeStore)
                    .tabItem {
                        Label("Library", systemImage: "books.vertical.fill")
                    }
                    .onAppear {
                        Task {
                            try await qrCodeStore.load()
                        }
                    }
                    .tag(Tab.History)
            }
        } else {
            TabView {
                OnboardingPageView(image: Image("AppIcon"), title: "QR Code Generator", description: "This app allows you to generate QR codes from text.")
                OnboardingPageView(image: Image(systemName: "square.and.arrow.up"), title: "Share Sheet", description: "You can add this app to the share sheet to generate QR codes from other apps.")
                VStack {
                    Text("Get Started")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 20)
                        .onTapGesture {
                            isOnboardingDone = true
                        }
                }
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Done")
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

#Preview {
    Group {
        @StateObject var qrCodeStore = QRCodeStore()
        @StateObject var storeKit = StoreKitManager()
        
        OnboardingView()
            .environmentObject(qrCodeStore)
            .environmentObject(storeKit)
    }
}