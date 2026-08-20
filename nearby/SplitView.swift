//
//  SplitView.swift
//  nearby
//
//  Created by Max Myron on 8/15/26.
//

import SwiftUI

private let initial: CGFloat = 0.1
private let middle: CGFloat = 0.5
private let full: CGFloat = 0.9

struct SplitView<TopContent: View, BottomContent: View>: View {
    private let detentFractions: [CGFloat] = [initial, middle, full]
    
    @Binding private var bottomViewOpacity: Double
    
    // current snapped detent fraction
    @State private var currentFraction: CGFloat = initial
    
    // offset from last detent fraction
    @State private var dragOffset: CGFloat = 0
    
    let topContent: TopContent
    let bottomContent: BottomContent
    
    @State private var isDragging: Bool = false
        
    init(bottomViewOpacity: Binding<Double>, @ViewBuilder top: () -> TopContent, @ViewBuilder bottom: () -> BottomContent) {
        self._bottomViewOpacity = bottomViewOpacity
        self.topContent = top()
        self.bottomContent = bottom()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height
            
            // Calculate actual height based on current fraction and active drag translation
            let rawHeight = (totalHeight * currentFraction) - dragOffset
            let targetBottomHeight = min(max(rawHeight, totalHeight * 0.1), totalHeight * 0.9)
            
            // collapsedPercentage is [0,1] between first two detents
            let activeFraction = targetBottomHeight / totalHeight
            let clampedFraction = min(max(activeFraction, initial), middle)
            let collapsedPercentage = (1.0 - ((clampedFraction - initial) / (middle - initial)))
            
            let bottomBorder = collapsedPercentage * 20
            
            ZStack(alignment: .bottom) {
                topContent
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .offset(y: -targetBottomHeight - 26)
                
                VStack (spacing: 0) {
                    DragHandle(isDragging: $isDragging)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                .onChanged {
                                    withAnimation(.interactiveSpring()) { isDragging = true }
                                    dragOffset = $0.translation.height
                                }
                                .onEnded { value in
                                    let isTap = abs(value.translation.height) < 5 && abs(value.translation.width) < 5
                                    
                                    if isTap {
                                        // cycle to next detent
                                        guard let currentIndex = detentFractions.firstIndex(of: currentFraction) else { return }
                                                                
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            currentFraction = detentFractions[(currentIndex + 1) % detentFractions.count]
                                            dragOffset = 0
                                            isDragging = false
                                        }
                                    } else {
                                        // snap current dragOffset to nearest detent\
                                        let endingHeight = (totalHeight * currentFraction) - value.translation.height
                                        let targetFraction = snapFraction(for: endingHeight / totalHeight)
                                        
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            currentFraction = targetFraction
                                            dragOffset = 0
                                            isDragging = false
                                        }
                                    }
                                }
                        )
                    
                    VStack {
                        bottomContent
                            .frame(width: geometry.size.width)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: geometry.size.width - (bottomBorder * 2))
                    .frame(height: targetBottomHeight, alignment: .top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: collapsedPercentage) { _, new in bottomViewOpacity = 1.0 - new }
        }
        .ignoresSafeArea()
    }
    
    private func snapFraction(for fraction: CGFloat) -> CGFloat {
        // Finds the closest detent to where the user let go
        return detentFractions.min(by: { abs($0 - fraction) < abs($1 - fraction) }) ?? 0.5
    }
}

struct DragHandle: View {
    @Binding var isDragging: Bool
    
    var body: some View {
        VStack {
            Capsule()
                .glassEffect()
                .frame(width: 80, height: 10)
                .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .scaleEffect(isDragging ? 0.8 : 1)
        .background(Color.black.opacity(0.0001))
    }
}

#Preview {
    return SplitView(bottomViewOpacity: .constant(0.0)) {
        Rectangle()
            .fill(Color.red)
    } bottom: {
        Rectangle()
            .fill(Color.blue)
    }
}

