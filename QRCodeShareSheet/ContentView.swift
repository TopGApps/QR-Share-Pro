import SwiftUI
import CoreImage.CIFilterBuiltins
import Photos

struct OnboardingView: View {
    @AppStorage("isOnboardingDone") private var isOnboardingDone = false

    var body: some View {
        if isOnboardingDone {
            ContentView()
        } else {
            TabView {
                OnboardingPageView(image: Image("AppIcon"), title: "QR Code Generator", description: "This app allows you to generate QR codes from text.")
                OnboardingPageView(image: Image(systemName: "square.and.arrow.up"), title: "Share Sheet", description: "You can add this app to the share sheet to generate QR codes from other apps.")
                VStack {
                    Text("Get Started")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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

struct ContentView: View {
    @State private var text = ""
    @State private var qrCodeImage: UIImage?
    @State private var showingSettings = false
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let qrCodeImage = qrCodeImage {
                        Image(uiImage: qrCodeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()

                        Button(action: {
                            UIImageWriteToSavedPhotosAlbum(qrCodeImage, nil, nil, nil)
                        }) {
                            Text("Save QR Code to Photos")
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                    }

                    ZStack(alignment: .topTrailing) {
                        TextEditor(text: $text)
                            .frame(minHeight: 200)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 0.5))
                            .onChange(of: text) { newValue in
                                generateQRCode(from: newValue)
                            }

                        Button(action: {
                            text = ""
                            qrCodeImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .padding()
                        }
                        .padding()
                    }

                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Spacer()
                            Text("Settings")
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                .onTapGesture {
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .navigationTitle("QR Code Generator")
        }
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
}

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                }
                Link("GitHub", destination: URL(string: "https://github.com/Visual-Studio-Coder/QRCodeShareSheet/")!)
                Link("Buy Me a Coffee", destination: URL(string: "https://www.buymeacoffee.com/")!)
            }

            Section {
                Button(action: {
                    // Share app
                }) {
                    Text("Share App")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Settings")
    }
}
