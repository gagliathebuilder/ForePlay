import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle.bold())
                            .foregroundColor(.fpNavy)
                        
                        Text("ForePlay v1.0")
                            .font(.headline)
                            .foregroundColor(.fpGreen)
                        
                        Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    // Introduction
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        Text("ForePlay records golf swing videos and provides optional voice guidance via CaDi on your device. We do not collect personal data, and your content remains stored locally unless you choose to export it.")
                            .font(.body)
                    }
                    
                    // Data We Access
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data We Access")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Camera: to record swings")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Microphone: for push-to-talk with CaDi")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Local Storage: to save your videos and settings")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Speech Recognition: to understand your voice input")
                            }
                        }
                        .font(.body)
                    }
                    
                    // What We Do Not Do
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Do Not Do")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("No analytics SDKs")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("No advertising or tracking")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("No cloud storage by default")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("No sharing of your swing data")
                            }
                        }
                        .font(.body)
                    }
                    
                    // OpenAI Integration (if applicable)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OpenAI Voice Integration")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        Text("If you enable OpenAI voices, your voice input and CaDi's responses are processed through OpenAI's TTS API. This data is not stored by OpenAI beyond the immediate request, and we do not have access to your OpenAI account or usage data.")
                            .font(.body)
                        
                        Text("OpenAI's privacy policy applies to their processing of this data.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Your Choices
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Choices")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Delete all local videos anytime in Settings")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Revoke camera/microphone permissions in iOS Settings")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Disable OpenAI voices in Settings")
                            }
                            
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Export and share videos only when you choose to")
                            }
                        }
                        .font(.body)
                    }
                    
                    // Children's Privacy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Children's Privacy")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        Text("ForePlay is not intended for children under 13. We do not knowingly collect personal information from children under 13.")
                            .font(.body)
                    }
                    
                    // Contact
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        Text("For questions about this privacy policy or to request data deletion:")
                            .font(.body)
                        
                        Text("your-email@yourdomain.com")
                            .font(.body)
                            .foregroundColor(.fpGreen)
                    }
                    
                    // Changes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Changes to This Policy")
                            .font(.headline)
                            .foregroundColor(.fpNavy)
                        
                        Text("We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the 'Last updated' date.")
                            .font(.body)
                    }
                    
                    // Footer
                    VStack(spacing: 8) {
                        Divider()
                        
                        Text("Your privacy is important to us. ForePlay is designed to keep your golf swing data private and secure.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss the view
                    }
                    .foregroundColor(.fpGreen)
                }
            }
        }
    }
}

// MARK: - Extensions
extension Color {
    static let fpGreen = Color(red: 0.173, green: 0.478, blue: 0.173)
    static let fpNavy = Color(red: 0.043, green: 0.145, blue: 0.271)
}

// MARK: - Preview
#if DEBUG
struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}
#endif
