//
//  EditProfileView.swift
//  Gym Flex Italia
//
//  Screen for editing user profile information
//

import SwiftUI

/// Edit Profile screen with form fields and save functionality
struct EditProfileView: View {
    
    @Environment(\.appContainer) private var appContainer
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = EditProfileViewModel()
    
    @State private var showSuccessAlert = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Form {
                // Error Banner
                if let error = viewModel.errorMessage {
                    Section {
                        InlineErrorBanner(
                            message: error,
                            type: .error,
                            onDismiss: { viewModel.clearError() }
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                
                // Success Banner
                if let success = viewModel.successMessage {
                    Section {
                        InlineErrorBanner(
                            message: success,
                            type: .success,
                            onDismiss: { viewModel.clearSuccess() }
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                
                // Personal Information
                Section {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppColors.brand)
                            .frame(width: 24)
                        TextField("Full Name", text: $viewModel.fullName)
                            .textContentType(.name)
                            .autocapitalization(.words)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppColors.brand)
                            .frame(width: 24)
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(AppColors.brand)
                            .frame(width: 24)
                        TextField("Phone Number", text: $viewModel.phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                } header: {
                    Text("Personal Information")
                }
                
                // Fitness Goals
                Section {
                    Picker(selection: $viewModel.selectedGoal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            HStack {
                                Image(systemName: goal.icon)
                                Text(goal.displayName)
                            }
                            .tag(goal)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(AppColors.brand)
                                .frame(width: 24)
                            Text("Fitness Goal")
                        }
                    }
                } header: {
                    Text("Fitness")
                }
                
                // Body Metrics (Optional)
                Section {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(AppColors.brand)
                            .frame(width: 24)
                        TextField("Height (cm)", text: $viewModel.heightCm)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(AppColors.brand)
                            .frame(width: 24)
                        TextField("Weight (kg)", text: $viewModel.weightKg)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Body Metrics (Optional)")
                } footer: {
                    Text("This information helps us personalize your fitness journey.")
                }
                
                // Account Info (Read-only)
                Section {
                    HStack {
                        Text("Member Since")
                            .foregroundColor(AppColors.textDim)
                        Spacer()
                        Text(viewModel.profile.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(AppColors.textHigh)
                    }
                    
                    HStack {
                        Text("Total Workouts")
                            .foregroundColor(AppColors.textDim)
                        Spacer()
                        Text("\(viewModel.profile.totalWorkouts)")
                            .foregroundColor(AppColors.textHigh)
                    }
                    
                    HStack {
                        Text("Current Streak")
                            .foregroundColor(AppColors.textDim)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(viewModel.profile.currentStreak) days")
                                .foregroundColor(AppColors.textHigh)
                        }
                    }
                } header: {
                    Text("Account")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingOverlayView(message: "Saving...")
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    DemoTapLogger.log("EditProfile.Save")
                    Task {
                        if await viewModel.save(using: appContainer.profileService) {
                            showSuccessAlert = true
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.brand)
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert("Profile Saved", isPresented: $showSuccessAlert) {
            Button("Done") {
                DemoTapLogger.log("EditProfile.Done")
                router.pop()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .task {
            await viewModel.load(using: appContainer.profileService)
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
