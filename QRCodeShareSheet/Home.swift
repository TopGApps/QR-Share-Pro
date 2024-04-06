//
//  Home.swift
//  QRCodeShareSheet
//
//  Created by Aaron Ma on 3/6/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import StoreKit

struct Home: View {
    @EnvironmentObject var qrCodeStore: QRCodeStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    
    @State private var showingAboutAppSheet = false
    @State private var text = ""
    @State private var textIsEmptyWithAnimation = true
    @State private var showSavePhotosQuestionAlert = false
    @State private var showSavedAlert = false
    @State private var showExceededLimitAlert = false
    @State private var showHistorySavedAlert = false
    @State private var showingWhatsNewAlert = false
    @State private var qrCodeImage: UIImage = UIImage()
    @State private var animatedText = ""
    
    let fullText = "Start typing to\ngenerate a QR code."
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    @FocusState private var isFocused
    
    @ObservedObject var accentColorManager = AccentColorManager.shared
    
    private var allIcons: [AppIcon] = [AppIcon(iconURL: "AppIcon", iconName: "Sky Blue (Default)"), AppIcon(iconURL: "AppIcon2", iconName: "Terminal Green"), AppIcon(iconURL: "AppIcon3", iconName: "Holographic Pink")]
    
    private func changeColor(to iconName: String) {
        switch iconName {
        case "AppIcon2":
            AccentColorManager.shared.accentColor = .green
        case "AppIcon3":
            AccentColorManager.shared.accentColor = Color(UIColor(red: 252/255, green: 129/255, blue: 158/255, alpha: 1))
        default:
            AccentColorManager.shared.accentColor = Color(#colorLiteral(red: 0.3860174716, green: 0.7137812972, blue: 0.937712729, alpha: 1))
        }
    }
    
    private func changeAppIcon(to iconURL: String) {
        let iconName = iconURL == "AppIcon" ? nil : iconURL
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        changeColor(to: iconName ?? "AppIcon")
    }
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    func save() async throws {
        qrCodeStore.save(history: qrCodeStore.history)
    }
    
    func generateQRCode(from string: String) {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let qrCode = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQrCode = qrCode.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledQrCode, from: scaledQrCode.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .opacity(textIsEmptyWithAnimation ? 0.2 : 1)
                    .overlay {
                        if text.isEmpty {
                            Text(animatedText)
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .bold()
                                .onReceive(timer) { _ in
                                    let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
                                    
                                    if animatedText.count < fullText.count {
                                        animatedText.append(fullText[fullText.index(fullText.startIndex, offsetBy: animatedText.count)])
                                        hapticGenerator.impactOccurred()
                                    } else {
                                        timer.upstream.connect().cancel()
                                    }
                                }
                        }
                    }
                
                HStack {
                    Spacer()
                    
                    Text("\(text.count)/2953 characters")
                        .foregroundStyle(text.count > 2953 ? .red : .secondary)
                        .bold()
                }
                .padding(.top, 3)
                .padding(.trailing)
                
                TextField("Create your own QR code...", text: $text)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .keyboardType(.webSearch)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: text) { newValue in
                        generateQRCode(from: newValue)
                        
                        withAnimation {
                            textIsEmptyWithAnimation = newValue.isEmpty
                        }
                    }
                    .onTapGesture {
                        isFocused = true
                    }
                    .onSubmit {
                        isFocused = false
                        
                        if text.count > 2953 {
                            showExceededLimitAlert = true
                        } else if !text.isEmpty {
                            showSavePhotosQuestionAlert = true
                        }
                    }
                    .focused($isFocused)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                
                Button {
                    if text.count > 2953 {
                        showExceededLimitAlert = true
                    } else {
                        showSavePhotosQuestionAlert = true
                    }
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.white)
                        .opacity(text.isEmpty ? 0.3 : 1)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(colorScheme == .dark ? 0.7 : 1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .disabled(text.isEmpty)
                .padding(.horizontal)
            }
            .navigationTitle("New QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                generateQRCode(from: "https://aaronhma.com")
            }
            .alert("Save to Photos?", isPresented: $showSavePhotosQuestionAlert) {
                Button("Yes") {
                    UIImageWriteToSavedPhotosAlbum(qrCodeImage, nil, nil, nil)
                    showSavedAlert = true
                    
                    let newCode = QRCode(text: text, qrCode: qrCodeImage.pngData())
                    qrCodeStore.history.append(newCode)
                    
                    Task {
                        do {
                            try await save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    showHistorySavedAlert = true
                }
                
                Button("No") {
                    let newCode = QRCode(text: text, qrCode: qrCodeImage.pngData())
                    qrCodeStore.history.append(newCode)
                    
                    Task {
                        do {
                            try await save()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    showHistorySavedAlert = true
                }
            }
            .alert("You'll need to remove \(text.count - 2953) characters first!", isPresented: $showExceededLimitAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert("Saved to Photos!", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert("Saved to History!", isPresented: $showHistorySavedAlert) {
                Button("OK", role: .cancel) {}
            }
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    let qrCodeImage = Image(uiImage: qrCodeImage)
                    
                    ShareLink(item: qrCodeImage, preview: SharePreview(text, image: qrCodeImage)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(text.isEmpty)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAboutAppSheet = true
                    } label: {
                        Label("About QR Share Pro", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAboutAppSheet) {
                NavigationStack {
                    List {
                        Section {
                            ShareLink(item: URL(string: "https://apps.apple.com/us/app/qr-share-pro/id6479589995")!) {
                                HStack {
                                    Image(uiImage: #imageLiteral(resourceName: UserDefaults.standard.string(forKey: "appIcon") ?? "AppIcon"))
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: .accentColor, radius: 5)
                                    
                                    VStack(alignment: .leading) {
                                        Text("QR Share Pro")
                                            .bold()
                                        
                                        Text("Version \(appVersion)")
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title)
                                        .bold()
                                        .foregroundStyle(.secondary)
                                }
                                .tint(.primary)
                            }
                            
                            Button {
                                requestReview()
                            } label: {
                                HStack {
                                    Label("Rate App", systemImage: "star")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                        
                        Section("Release Notes") {
                            Button {
                                showingWhatsNewAlert = true
                            } label: {
                                HStack {
                                    Label("TestFlight RC 1", systemImage: "hammer")
                                        .bold()
                                    Spacer()
                                    Text("April 6, 2024")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button {
                                showingWhatsNewAlert = true
                            } label: {
                                Text("See what's new...")
                                    .bold()
                            }
                        }
                        .alert("Release Candidate 1 contains:\n\n- History, History detail, and New QR code view finished! 🥳\n- Scanner improvements & updates\n- Full passkey support\n- Bug fixes & improvements", isPresented: $showingWhatsNewAlert) {}
                        
                        Section("App Icon & Theme") {
                            ForEach(allIcons) { i in
                                Button {
                                    changeAppIcon(to: i.iconURL)
                                    UserDefaults.standard.set(i.iconURL, forKey: "appIcon")
                                } label: {
                                    HStack {
                                        Image(systemName: i.iconURL == UserDefaults.standard.string(forKey: "appIcon") ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .tint(.accentColor)
                                        
                                        Image(uiImage: #imageLiteral(resourceName: i.iconURL))
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(radius: 50)
                                        
                                        Text(i.iconName)
                                            .tint(.primary)
                                    }
                                }
                            }
                        }
                        
                        Section("Credits") {
                            Button {
                                if let url = URL(string: "https://github.com/Visual-Studio-Coder") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                VStack {
                                    HStack {
                                        Label("Vaibhav Satishkumar", systemImage: "person")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .tint(.secondary)
                                    }
                                }
                            }
                            .tint(.primary)
                            
                            Button {
                                if let url = URL(string: "https://aaronhma.com") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Label("Aaron Ma", systemImage: "person")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .tint(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                        
                        Section("Product Improvement") {
                            Button {
                                if let url = URL(string: "https://github.com/Visual-Studio-Coder/QRCodeShareSheet") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Label("Contribute", systemImage: "chevron.left.forwardslash.chevron.right")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .tint(.secondary)
                                }
                            }
                            .tint(.primary)
                            
                            Button {
                                if let url = URL(string: "https://github.com/Visual-Studio-Coder/QRCodeShareSheet/issues/new?assignees=&labels=&projects=&template=bug_report.md&title=") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Label("Bug Report", systemImage: "ladybug")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .tint(.secondary)
                                }
                            }
                            .tint(.primary)
                            
                            Button {
                                if let url = URL(string: "https://github.com/Visual-Studio-Coder/QRCodeShareSheet/issues/new?assignees=&labels=&projects=&template=feature_request.md&title=") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Label("Feature Request", systemImage: "lightbulb")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .tint(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                    }
                    .accentColor(accentColorManager.accentColor)
                    .navigationBarTitle("About QR Share Pro")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showingAboutAppSheet = false
                            } label: {
                                Text("Done")
                                    .tint(accentColorManager.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: isFocused) { focus in
            if focus {
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}

#Preview {
    Group {
        @StateObject var qrCodeStore = QRCodeStore()
        
        Home()
            .environmentObject(qrCodeStore)
    }
}
