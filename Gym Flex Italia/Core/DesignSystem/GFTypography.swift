//
//  GFTypography.swift
//  Gym Flex Italia
//
//  Design System: Typography tokens with clear hierarchy
//

import SwiftUI

/// Design System typography tokens
enum GFTypography {
    
    // MARK: - Weights
    
    enum Weight {
        case regular
        case medium
        case semibold
        case bold
        
        var fontWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }
    
    // MARK: - Hero Modifier (Largest, for key values)
    
    struct HeroModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 48, weight: weight.fontWeight, design: .rounded))
        }
    }
    
    // MARK: - Large Title Modifier
    
    struct LargeTitleModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 28, weight: weight.fontWeight, design: .default))
        }
    }
    
    // MARK: - Title Modifier
    
    struct TitleModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 20, weight: weight.fontWeight, design: .default))
        }
    }
    
    // MARK: - Section Modifier
    
    struct SectionModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 15, weight: weight.fontWeight, design: .default))
        }
    }
    
    // MARK: - Body Modifier
    
    struct BodyModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 15, weight: weight.fontWeight, design: .default))
        }
    }
    
    // MARK: - Caption Modifier
    
    struct CaptionModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 13, weight: weight.fontWeight, design: .default))
        }
    }
    
    // MARK: - Meta Modifier (smallest, for timestamps, IDs)
    
    struct MetaModifier: ViewModifier {
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 11, weight: weight.fontWeight, design: .default))
        }
    }
    
    // MARK: - Value Modifier (for numeric values, prices)
    
    struct ValueModifier: ViewModifier {
        let size: CGFloat
        let weight: Weight
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: size, weight: weight.fontWeight, design: .rounded))
        }
    }
    
    // MARK: - Factory Methods
    
    static func hero(_ weight: Weight = .bold) -> HeroModifier {
        HeroModifier(weight: weight)
    }
    
    static func largeTitle(_ weight: Weight = .bold) -> LargeTitleModifier {
        LargeTitleModifier(weight: weight)
    }
    
    static func title(_ weight: Weight = .semibold) -> TitleModifier {
        TitleModifier(weight: weight)
    }
    
    static func section(_ weight: Weight = .semibold) -> SectionModifier {
        SectionModifier(weight: weight)
    }
    
    static func body(_ weight: Weight = .regular) -> BodyModifier {
        BodyModifier(weight: weight)
    }
    
    static func caption(_ weight: Weight = .regular) -> CaptionModifier {
        CaptionModifier(weight: weight)
    }
    
    static func meta(_ weight: Weight = .regular) -> MetaModifier {
        MetaModifier(weight: weight)
    }
    
    static func value(size: CGFloat = 24, weight: Weight = .bold) -> ValueModifier {
        ValueModifier(size: size, weight: weight)
    }
}

// MARK: - View Extensions

extension View {
    /// Hero text - largest, for key values like timers
    func gfHero(_ weight: GFTypography.Weight = .bold) -> some View {
        modifier(GFTypography.hero(weight))
    }
    
    /// Large title - for screen headers
    func gfLargeTitle(_ weight: GFTypography.Weight = .bold) -> some View {
        modifier(GFTypography.largeTitle(weight))
    }
    
    /// Title - for card titles, section headers
    func gfTitle(_ weight: GFTypography.Weight = .semibold) -> some View {
        modifier(GFTypography.title(weight))
    }
    
    /// Section - for subsection headers
    func gfSection(_ weight: GFTypography.Weight = .semibold) -> some View {
        modifier(GFTypography.section(weight))
    }
    
    /// Body - for primary content
    func gfBody(_ weight: GFTypography.Weight = .regular) -> some View {
        modifier(GFTypography.body(weight))
    }
    
    /// Caption - for secondary content
    func gfCaption(_ weight: GFTypography.Weight = .regular) -> some View {
        modifier(GFTypography.caption(weight))
    }
    
    /// Meta - for timestamps, IDs, smallest text
    func gfMeta(_ weight: GFTypography.Weight = .regular) -> some View {
        modifier(GFTypography.meta(weight))
    }
    
    /// Value - for numeric values, prices (rounded design)
    func gfValue(size: CGFloat = 24, weight: GFTypography.Weight = .bold) -> some View {
        modifier(GFTypography.value(size: size, weight: weight))
    }
}

