//
//  TabButton.swift
//  ChatGateMac
//
//  Created by KsArT on 12.11.2025.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let icon: String
    let iconTime: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            if isSelected || !iconTime.isEmpty {
                Image(systemName: isSelected ? "target" : iconTime)
                    .font(.system(size: 8))
            }
//            Text(title)
//                .font(.caption)
        }
        .frame(maxHeight: .infinity)
        .frame(width: 100)
        .foregroundColor(isSelected ? .accentColor : .secondary)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}
