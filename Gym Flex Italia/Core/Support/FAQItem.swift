//
//  FAQItem.swift
//  Gym Flex Italia
//
//  Model for FAQ items.
//

import Foundation

/// Represents a FAQ question and answer
struct FAQItem: Identifiable, Hashable {
    let id: String
    let question: String
    let answer: String
    
    init(id: String = UUID().uuidString, question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
}
