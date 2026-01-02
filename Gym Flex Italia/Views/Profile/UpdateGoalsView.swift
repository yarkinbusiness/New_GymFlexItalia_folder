//
//  UpdateGoalsView.swift
//  Gym Flex Italia
//
//  View for updating fitness goals.
//

import SwiftUI

/// Fitness goals editing view
struct UpdateGoalsView: View {
    
    @StateObject private var viewModel = UpdateGoalsViewModel()
    @EnvironmentObject var router: AppRouter
    @Environment(\.appContainer) var appContainer
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.profile == nil {
                errorView(error)
            } else {
                contentView
            }
        }
        .navigationTitle("Fitness Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        saveGoals()
                    }
                    .disabled(viewModel.profile == nil)
                }
            }
        }
        .task {
            await viewModel.load(using: appContainer.profileService)
        }
        .toast("Goals updated!", isPresented: .constant(viewModel.successMessage != nil))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brand))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(AppFonts.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.danger)
            
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.load(using: appContainer.profileService)
                }
            }
            .font(AppFonts.label)
            .foregroundColor(AppColors.brand)
        }
        .padding()
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.brand)
                    
                    Text("Select Your Goals")
                        .font(AppFonts.h3)
                        .foregroundColor(.primary)
                    
                    Text("Choose the fitness goals that motivate you")
                        .font(AppFonts.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, Spacing.lg)
                
                // Goals List
                goalsListView
                
                // Selected Count
                Text("\(viewModel.selectedGoals.count) goal\(viewModel.selectedGoals.count == 1 ? "" : "s") selected")
                    .font(AppFonts.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, Spacing.md)
                
                // Error Message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.danger)
                        
                        Text(error)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.danger)
                    }
                    .padding()
                    .background(AppColors.danger.opacity(0.1))
                    .cornerRadius(CornerRadii.md)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Goals List
    
    private var goalsListView: some View {
        VStack(spacing: Spacing.md) {
            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                goalRow(goal)
            }
        }
    }
    
    private func goalRow(_ goal: FitnessGoal) -> some View {
        let isSelected = viewModel.isGoalSelected(goal)
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleGoal(goal)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AppGradients.primary : LinearGradient(colors: [Color(.tertiarySystemFill)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                    
                    Text(goalDescription(for: goal))
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.brand : Color(.tertiarySystemFill), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AppColors.brand)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? AppColors.brand.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadii.lg)
                    .stroke(isSelected ? AppColors.brand : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func goalDescription(for goal: FitnessGoal) -> String {
        switch goal {
        case .loseWeight: return "Cardio and calorie-burning workouts"
        case .buildMuscle: return "Strength training and resistance exercises"
        case .improveEndurance: return "Stamina-building and HIIT workouts"
        case .increaseFlexibility: return "Yoga, stretching, and mobility work"
        case .stayActive: return "Regular movement and activity"
        case .generalFitness: return "Overall health and wellness"
        }
    }
    
    private func saveGoals() {
        Task {
            let success = await viewModel.save(using: appContainer.profileService)
            if success {
                // Pop back after short delay
                try? await Task.sleep(nanoseconds: 800_000_000)
                router.pop()
            }
        }
    }
}

#Preview {
    NavigationStack {
        UpdateGoalsView()
    }
    .environmentObject(AppRouter())
    .environment(\.appContainer, .demo())
}
