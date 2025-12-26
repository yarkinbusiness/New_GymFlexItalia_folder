//
//  WeeklyProgressView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Weekly workout progress view
struct WeeklyProgressView: View {
    
    let stats: WorkoutStats
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("This Week")
                    .font(.headline)
                
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<7) { index in
                        DayBar(
                            day: dayName(for: index),
                            hasWorkout: index < stats.weeklyWorkouts
                        )
                    }
                }
                
                HStack {
                    StatItem(
                        title: "Workouts",
                        value: "\(stats.weeklyWorkouts)",
                        icon: "dumbbell.fill",
                        color: .blue
                    )
                    
                    Spacer()
                    
                    StatItem(
                        title: "Streak",
                        value: "\(stats.currentStreak)",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    Spacer()
                    
                    StatItem(
                        title: "Total",
                        value: "\(stats.totalWorkouts)",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
        }
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[index]
    }
}

struct DayBar: View {
    let day: String
    let hasWorkout: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(hasWorkout ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 30, height: hasWorkout ? 60 : 30)
            
            Text(day)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WeeklyProgressView(stats: WorkoutStats(
        totalWorkouts: 42,
        totalMinutes: 2100,
        totalCalories: nil,
        currentStreak: 5,
        longestStreak: 12,
        weeklyWorkouts: 4,
        monthlyWorkouts: 16,
        favoriteGym: nil,
        favoriteWorkoutType: nil
    ))
    .padding()
}

