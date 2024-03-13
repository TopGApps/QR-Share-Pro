//
//  Home.swift
//  QRCodeShareSheet
//
//  Created by Aaron Ma on 3/6/24.
//

import SwiftUI
import PhotosUI
import CoreImage.CIFilterBuiltins
import StoreKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: Image?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let selectedImage = results.first {
                selectedImage.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let uiImage = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
            picker.dismiss(animated: true)
            //            self.parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct AppIcon: Identifiable {
    var id = UUID()
    var iconURL: String
    var iconName: String
    var proRequired: Bool = true
}

struct ClearButton: ViewModifier
{
    @Binding var text: String
    
    public func body(content: Content) -> some View
    {
        ZStack(alignment: .trailing)
        {
            content
            
            if !text.isEmpty
            {
                Button {
                    self.text = ""
                } label: {
                    Image(systemName: "delete.left")
                        .foregroundColor(Color(UIColor.opaqueSeparator))
                }
                .padding(.trailing, 15)
            }
        }
    }
}

struct Home: View {
    @EnvironmentObject var qrCodeStore: QRCodeStore
    @EnvironmentObject var storeKit: StoreKitManager
    
    @State private var showingAboutAppSheet = false
    @State private var showingGetProSheet = false
    
    @State private var boughtPro = false
    
    @State private var text = ""
    @State private var showSaveAlert = false
    @State private var showSavedAlert = false
    @State private var showHistorySavedAlert = false
    @State private var qrCodeImage: UIImage?
    
    @State private var showingBrandingLogoSheet = false
    
    @State private var colorSelection = Color.black
    
    @State private var brandingImage: Image?
    
    //    @State private var animateGradient = false
    
    private var allIcons: [AppIcon] = [AppIcon(iconURL: "AppIcon", iconName: "Default", proRequired: false), AppIcon(iconURL: "AppIcon2", iconName: "Terminal", proRequired: false), AppIcon(iconURL: "AppIcon3", iconName: "Hologram", proRequired: false), AppIcon(iconURL: "AppIcon3", iconName: "Pro 1"), AppIcon(iconURL: "AppIcon2", iconName: "Pro 2"), AppIcon(iconURL: "AppIcon", iconName: "Pro 3")]
    
    @State private var currentlySelected = "AppIcon"
    
    private func changeAppIcon(to iconURL: String) {
        let iconName = iconURL == "AppIcon" ? nil : iconURL
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    func save() async throws {
        try await qrCodeStore.save(history: qrCodeStore.history)
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
    
    func appVersion(in bundle: Bundle = .main) -> String {
        guard let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            fatalError("CFBundleShortVersionString missing from info dictionary")
        }
        
        return version
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                //                RadialGradient(colors: [.gray, .white], center: .center, startRadius: animateGradient ? 400 : 200, endRadius: animateGradient ? 20 : 40)
                ////                    .frame(height: UIScreen.main.bounds.height * 0.2)
                //                    .ignoresSafeArea()
                //                    .onAppear {
                //                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                //                            animateGradient.toggle()
                //                        }
                //                    }
                
                Form {
                    if !text.isEmpty {
                        if let qrCodeImage = qrCodeImage {
                            if let brandingImage = brandingImage {
                                Image(uiImage: qrCodeImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        brandingImage
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    )
                            } else {
                                Image(uiImage: qrCodeImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        Image(uiImage: #imageLiteral(resourceName: "AppIcon"))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    )
                            }
                        }
                    }
                    
                    TextField("Start typing...", text: $text)
                    //                        .keyboardType(.webSearch)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    //                        .autocorrectionType(.none)
                    //                        .modifier(ClearButton(text: $text))
                    //                        .focused(true)
                        .onChange(of: text) { newValue in
                            generateQRCode(from: newValue)
                        }
                    //                        .onTapGesture {
                    //                            // Dismiss keyboard
                    //                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    //                        }
                    
                    Section {
                        if !boughtPro {
                            HStack {
                                Label("Color", systemImage: "paintbrush")
                                Spacer()
                                Label("Pro Required", systemImage: "lock")
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Label("Branding Logo", systemImage: "briefcase")
                                Spacer()
                                Label("Pro Required", systemImage: "lock")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack {
                                Label("Color", systemImage: "paintbrush")
                                Spacer()
                                ColorPicker("", selection: $colorSelection)
                            }
                            
                            Button {
                                showingBrandingLogoSheet = true
                            } label: {
                                HStack {
                                    Label("Branding Logo", systemImage: "briefcase")
                                    Spacer()
                                    Text("Choose")
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                    } header: {
                        Text("QR Code Theme")
                    }
                    
                    if !text.isEmpty {
                        Section {
                            Button {
                                showSaveAlert = true
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            .tint(.primary)
                            .alert("Choose Save Location", isPresented: $showSaveAlert) {
                                HStack {
                                    Button("Photos") {
                                        if let qrCodeImage = qrCodeImage {
                                            UIImageWriteToSavedPhotosAlbum(qrCodeImage, nil, nil, nil)
                                            showSavedAlert = true
                                        }
                                    }
                                    Button("QR Share Library") {
                                        if let qrCodeImage = qrCodeImage {
                                            let newCode = QRCode(text: text, qrCode: qrCodeImage.pngData())
                                            
                                            qrCodeStore.history.append(newCode)
                                            
                                            Task {
                                                do {
                                                    try await save()
                                                } catch {
                                                    fatalError(error.localizedDescription)
                                                }
                                            }
                                            
                                            showHistorySavedAlert = true
                                        }
                                    }
                                }
                                
                                Button("Cancel", role: .cancel) {}
                            }
                            .alert("Saved to Photos!", isPresented: $showSavedAlert) {
                                Button("OK", role: .cancel) {}
                            }
                            .alert("Saved to Library!", isPresented: $showHistorySavedAlert) {
                                Button("OK", role: .cancel) {}
                            }
                        } header: {
                            Text("Save")
                        }
                    }
                }
                .navigationTitle("New QR Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {} label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAboutAppSheet = true
                        } label: {
                            Label("About QR Share", systemImage: "info.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingBrandingLogoSheet) {
                    ImagePicker(selectedImage: $brandingImage)
                }
                .sheet(isPresented: $showingAboutAppSheet) {
                    NavigationView {
                        List {
                            if !boughtPro {
                                Section {
                                    NavigationLink {
                                        GetPro()
                                            .environmentObject(storeKit)
                                    } label: {
                                        Label("**QR Share Pro** - $1.99", systemImage: "crown.fill")
                                    }
                                }
                            }
                            
                            Section {
                                HStack {
                                    Image(uiImage: #imageLiteral(resourceName: currentlySelected))
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    
                                    VStack(alignment: .leading) {
                                        Text(boughtPro ? "QR Share Pro" : "QR Share")
                                            .bold()
                                        Text("Version \(appVersion())")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Button {
                                } label: {
                                    HStack {
                                        Label("Rate App", systemImage: "star")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                //                                .buttonStyle(.bordered)
                                //                                           .tint(.teal) // set the tint
                                //                                           .controlSize(.large)
                                //                                           .controlProminence(.increased) // increase the prominence
                                
                                HStack {
                                    Label("Share App", systemImage: "square.and.arrow.up")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(.secondary)
                                }
                            } header: {
                                Text(boughtPro ? "QR Share Pro" : "QR Share")
                            }
                            
                            Section {
                                ForEach(allIcons) { i in
                                    Button {
                                        changeAppIcon(to: i.iconURL)
                                        currentlySelected = i.iconURL
                                    } label: {
                                        HStack {
                                            if i.proRequired {
                                                Image(systemName: "lock")
                                                    .font(.title2)
                                                    .tint(.secondary)
                                            } else {
                                                Image(systemName: i.iconURL == currentlySelected ? "checkmark.circle.fill" : "circle")
                                                    .font(.title2)
                                                    .tint(.blue)
                                            }
                                            
                                            Image(uiImage: #imageLiteral(resourceName: i.iconURL))
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .shadow(radius: 50)
                                            
                                            Text(i.iconName)
                                                .tint(.primary)
                                            
                                            if i.proRequired {
                                                Spacer()
                                                Text("Pro Required")
                                                    .tint(.secondary)
                                            }
                                        }
                                    }
                                }
                            } header: {
                                Text("App Icon")
                            }
                        }
                        .navigationBarTitle("About QR Share")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingAboutAppSheet = false
                                } label: {
                                    Text("Done")
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingGetProSheet) {
                    NavigationView {
                        GetPro()
                            .environmentObject(storeKit)
                    }
                }
            }
        }
        .onChange(of: storeKit.purchasedPlan) { course in
            Task {
                boughtPro = (try? await storeKit.isPurchased(storeKit.storeProducts[0])) ?? false
            }
        }
        .onAppear {
            Task {
                if !storeKit.storeProducts.isEmpty {
                    boughtPro = (try? await storeKit.isPurchased(storeKit.storeProducts[0])) ?? false
                }
                
#if targetEnvironment(simulator)
                boughtPro = true
#endif
            }
        }
    }
}

#Preview {
    Group {
        @StateObject var qrCodeStore = QRCodeStore()
        @StateObject var storeKit = StoreKitManager()
        
        Home()
            .environmentObject(qrCodeStore)
            .environmentObject(storeKit)
    }
}