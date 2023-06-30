//
//  AvatarStoryIndicatorComponent.swift
//  Telegram
//
//  Created by Mike Renoir on 30.06.2023.
//  Copyright © 2023 Telegram. All rights reserved.
//

import Foundation
import TGUIKit
import TelegramCore

public final class AvatarStoryIndicatorComponent {
    public struct Counters: Equatable {
        public var totalCount: Int
        public var unseenCount: Int
        
        public init(totalCount: Int, unseenCount: Int) {
            self.totalCount = totalCount
            self.unseenCount = unseenCount
        }
    }
    
    public let hasUnseen: Bool
    public let hasUnseenCloseFriendsItems: Bool
    public let theme: PresentationTheme
    public let activeLineWidth: CGFloat
    public let inactiveLineWidth: CGFloat
    public let counters: Counters?
    
    public init(
        hasUnseen: Bool,
        hasUnseenCloseFriendsItems: Bool,
        theme: PresentationTheme,
        activeLineWidth: CGFloat,
        inactiveLineWidth: CGFloat,
        counters: Counters?
    ) {
        self.hasUnseen = hasUnseen
        self.hasUnseenCloseFriendsItems = hasUnseenCloseFriendsItems
        self.theme = theme
        self.activeLineWidth = activeLineWidth
        self.inactiveLineWidth = inactiveLineWidth
        self.counters = counters
    }
    public convenience init(story: EngineStorySubscriptions.Item, presentation: PresentationTheme) {
        self.init(hasUnseen: story.hasUnseen, hasUnseenCloseFriendsItems: story.hasUnseenCloseFriends, theme: presentation, activeLineWidth: 1.5, inactiveLineWidth: 1.0, counters: .init(totalCount: story.storyCount, unseenCount: story.unseenCount))
    }
    
    public static func ==(lhs: AvatarStoryIndicatorComponent, rhs: AvatarStoryIndicatorComponent) -> Bool {
        if lhs.hasUnseen != rhs.hasUnseen {
            return false
        }
        if lhs.hasUnseenCloseFriendsItems != rhs.hasUnseenCloseFriendsItems {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.activeLineWidth != rhs.activeLineWidth {
            return false
        }
        if lhs.inactiveLineWidth != rhs.inactiveLineWidth {
            return false
        }
        if lhs.counters != rhs.counters {
            return false
        }
        return true
    }
    
    public final class IndicatorView : View {
        
        private final class Drawer: View {
            
            required init(frame frameRect: NSRect) {
                super.init(frame: frameRect)
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            func update(component: AvatarStoryIndicatorComponent, progress: CGFloat, availableSize: CGSize) -> CGSize {
                self.availableSize = availableSize
                self.component = component
                self.progress = progress
                needsDisplay = true
                return availableSize
            }
            
            private var availableSize: NSSize = .zero
            private var component: AvatarStoryIndicatorComponent?
            private var progress: CGFloat = 1.0
            
            override func draw(_ layer: CALayer, in context: CGContext) {
                guard let component = self.component else {
                    return
                }
                
                let size = layer.frame.size
                
                let lineWidth: CGFloat
                let diameter: CGFloat
                
                if component.hasUnseen {
                    lineWidth = component.activeLineWidth
                } else {
                    lineWidth = component.inactiveLineWidth
                }
                let maxOuterInset = component.activeLineWidth + component.activeLineWidth
                diameter = availableSize.width + maxOuterInset * 2.0
                let imageDiameter = availableSize.width + maxOuterInset * 2.0
                
                
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                let activeColors: [CGColor]
                let inactiveColors: [CGColor]
                
                if component.hasUnseenCloseFriendsItems {
                    activeColors = [
                        NSColor(rgb: 0x7CD636).cgColor,
                        NSColor(rgb: 0x26B470).cgColor
                    ]
                } else {
                    activeColors = [
                        NSColor(rgb: 0x34C76F).cgColor,
                        NSColor(rgb: 0x3DA1FD).cgColor
                    ]
                }
                
                if component.theme.colors.isDark {
                    inactiveColors = [component.theme.colors.grayIcon.withAlphaComponent(0.5).cgColor, component.theme.colors.grayIcon.withAlphaComponent(0.5).cgColor]
                } else {
                    inactiveColors = [NSColor(rgb: 0xD8D8E1).cgColor, NSColor(rgb: 0xD8D8E1).cgColor]
                }
                
                var locations: [CGFloat] = [0.0, 1.0]
                
                context.setLineWidth(lineWidth)
                
                if let counters = component.counters, counters.totalCount > 1 {
                    let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                    let radius = (diameter - lineWidth) * 0.5
                    let spacing: CGFloat = 3.0 * progress
                    let angularSpacing: CGFloat = spacing / radius
                    let circleLength = CGFloat.pi * 2.0 * radius
                    let segmentLength = (circleLength - spacing * CGFloat(counters.totalCount)) / CGFloat(counters.totalCount)
                    let segmentAngle = segmentLength / radius
                    
                    for pass in 0 ..< 2 {
                        context.resetClip()
                        
                        let startIndex: Int
                        let endIndex: Int
                        if pass == 0 {
                            startIndex = 0
                            endIndex = counters.totalCount - counters.unseenCount
                        } else {
                            startIndex = counters.totalCount - counters.unseenCount
                            endIndex = counters.totalCount
                        }
                        if startIndex < endIndex {
                            for i in startIndex ..< endIndex {
                                let startAngle = CGFloat(i) * (angularSpacing + segmentAngle) - CGFloat.pi * 0.5 + angularSpacing * 0.5
                                context.move(to: CGPoint(x: center.x + cos(startAngle) * radius, y: center.y + sin(startAngle) * radius))
                                context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: startAngle + segmentAngle, clockwise: false)
                            }
                            context.setLineCap(.round)

                            context.replacePathWithStrokedPath()
                            context.clip()
                            
                            let colors: [CGColor]
                            if pass == 1 {
                                colors = activeColors
                            } else {
                                colors = inactiveColors
                            }
                            
                            let colorSpace = CGColorSpaceCreateDeviceRGB()
                            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: &locations)!
                            
                            context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
                        }
                    }
                } else {
                    let ellipse = CGRect(origin: CGPoint(x: size.width * 0.5 - diameter * 0.5, y: size.height * 0.5 - diameter * 0.5), size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5)
                    context.addEllipse(in: ellipse)
                    
                    context.replacePathWithStrokedPath()
                    context.clip()
                    
                    let colors: [CGColor]
                    if component.hasUnseen {
                        colors = activeColors
                    } else {
                        colors = inactiveColors
                    }
                    
                    let colorSpace = CGColorSpaceCreateDeviceRGB()
                    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: &locations)!
                    
                    context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
                }
            }
        }
    
        
        private let indicatorView: Drawer = Drawer(frame: .zero)
        
        private var component: AvatarStoryIndicatorComponent?
        
        required init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(self.indicatorView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func update(component: AvatarStoryIndicatorComponent, availableSize: CGSize, progress: CGFloat = 1.0, transition: ContainedViewLayoutTransition) -> CGSize {
            self.component = component
            
            let maxOuterInset = component.activeLineWidth + component.activeLineWidth
            let imageDiameter = availableSize.width + maxOuterInset * 2.0

            let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: imageDiameter, height: imageDiameter))
            transition.updateFrame(view: self.indicatorView, frame: rect)
            
            return self.indicatorView.update(component: component, progress: progress, availableSize: availableSize)
        }
    }
    
}

