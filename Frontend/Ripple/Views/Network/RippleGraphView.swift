import SwiftUI

struct RippleGraphView: View {
    let contacts: [NetworkContact]
    let userInitials: String
    let userAvatarURL: URL?
    var onSelectContact: (NetworkContact) -> Void

    @State private var pulsePhase: CGFloat = 0
    @State private var userAvatarImage: UIImage?
    @State private var contactAvatarImages: [String: UIImage] = [:]

    private let ringRadii: [CGFloat] = [70, 120, 170]
    private let maxDotsPerContact = 5
    private let dotRadius: CGFloat = 5
    private let dotSpreadRadius: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy: CGFloat = 200
            let r1: CGFloat = min(geo.size.width * 0.23, 100)

            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: cx, y: cy)

                    for (i, baseR) in ringRadii.enumerated() {
                        let scale = 1.0 + sin(pulsePhase + Double(i) * 0.8) * 0.03
                        let r = baseR * scale
                        let opacity = 0.07 + sin(pulsePhase + Double(i) * 0.5) * 0.04
                        var ringPath = Path()
                        ringPath.addEllipse(in: CGRect(
                            x: center.x - r, y: center.y - r,
                            width: r * 2, height: r * 2
                        ))
                        context.stroke(
                            ringPath,
                            with: .color(.white.opacity(opacity)),
                            lineWidth: 1.5
                        )
                    }

                    let nodePositions = self.nodePositions(cx: cx, cy: cy, r1: r1)

                    // Dashed lines: center → ring 1
                    for pos in nodePositions {
                        var linePath = Path()
                        linePath.move(to: center)
                        linePath.addLine(to: pos.point)
                        context.stroke(
                            linePath,
                            with: .color(.white.opacity(0.16)),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 5])
                        )
                    }

                    // Second-degree dots + lines from ring-1 contacts
                    for (i, pos) in nodePositions.enumerated() {
                        guard i < contacts.count else { break }
                        let contact = contacts[i]
                        let count = min(contact.secondDegreeCount, maxDotsPerContact)
                        guard count > 0 else { continue }

                        let dotPositions = self.secondDegreePositions(
                            around: pos.point,
                            parentAngle: pos.angle,
                            count: count
                        )
                        for dotPos in dotPositions {
                            var line = Path()
                            line.move(to: pos.point)
                            line.addLine(to: dotPos)
                            context.stroke(
                                line,
                                with: .color(.white.opacity(0.10)),
                                style: StrokeStyle(lineWidth: 0.8, dash: [2, 4])
                            )

                            var dot = Path()
                            dot.addEllipse(in: CGRect(
                                x: dotPos.x - dotRadius,
                                y: dotPos.y - dotRadius,
                                width: dotRadius * 2,
                                height: dotRadius * 2
                            ))
                            context.fill(dot, with: .color(.white.opacity(0.30)))
                            context.stroke(dot, with: .color(.white.opacity(0.15)), lineWidth: 0.5)
                        }
                    }

                    // Ring 1 contact nodes
                    for (i, pos) in nodePositions.enumerated() {
                        guard i < contacts.count else { break }
                        let contact = contacts[i]

                        let glowRect = CGRect(
                            x: pos.point.x - 30, y: pos.point.y - 30,
                            width: 60, height: 60
                        )
                        var glowPath = Path()
                        glowPath.addEllipse(in: glowRect)
                        context.fill(glowPath, with: .color(contact.avatarColor.opacity(0.16)))

                        let mainRect = CGRect(
                            x: pos.point.x - 24, y: pos.point.y - 24,
                            width: 48, height: 48
                        )

                        let avatarImg = contactAvatarImages[contact.id] ?? contact.thumbnailImage
                        if let img = avatarImg {
                            var mainPath = Path()
                            mainPath.addEllipse(in: mainRect)
                            context.fill(mainPath, with: .color(contact.avatarColor))
                            let resolved = context.resolve(Image(uiImage: img))
                            let fillRect = aspectFillRect(imageSize: resolved.size, in: mainRect)
                            context.clipToLayer(opacity: 1) { ctx in
                                var clipPath = Path()
                                clipPath.addEllipse(in: mainRect)
                                ctx.clip(to: clipPath)
                                ctx.draw(resolved, in: fillRect)
                            }
                        } else {
                            var mainPath = Path()
                            mainPath.addEllipse(in: mainRect)
                            context.fill(mainPath, with: .color(contact.avatarColor))

                            let initialsText = Text(contact.initials)
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                            context.draw(
                                context.resolve(initialsText),
                                at: pos.point,
                                anchor: .center
                            )
                        }

                        if contact.secondDegreeCount > 0 {
                            let badgeCenter = CGPoint(x: pos.point.x + 18, y: pos.point.y - 18)
                            let badgeRect = CGRect(
                                x: badgeCenter.x - 11, y: badgeCenter.y - 11,
                                width: 22, height: 22
                            )
                            var badgePath = Path()
                            badgePath.addEllipse(in: badgeRect)
                            context.fill(badgePath, with: .color(.white))

                            let badgeText = Text("\(contact.secondDegreeCount)")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(NetworkColors.darkBlue)
                            context.draw(
                                context.resolve(badgeText),
                                at: badgeCenter,
                                anchor: .center
                            )
                        }
                    }

                    // Center user node
                    var outerGlow = Path()
                    outerGlow.addEllipse(in: CGRect(x: center.x - 42, y: center.y - 42, width: 84, height: 84))
                    context.fill(outerGlow, with: .color(.white.opacity(0.07)))

                    var midRing = Path()
                    midRing.addEllipse(in: CGRect(x: center.x - 33, y: center.y - 33, width: 66, height: 66))
                    context.fill(midRing, with: .color(.white.opacity(0.16)))

                    var youCircle = Path()
                    youCircle.addEllipse(in: CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52))
                    context.fill(youCircle, with: .color(.white))

                    if let avatarImg = userAvatarImage {
                        let resolved = context.resolve(Image(uiImage: avatarImg))
                        let avatarRect = CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52)
                        let fillRect = aspectFillRect(imageSize: resolved.size, in: avatarRect)
                        context.clipToLayer(opacity: 1) { ctx in
                            var clipPath = Path()
                            clipPath.addEllipse(in: avatarRect)
                            ctx.clip(to: clipPath)
                            ctx.draw(resolved, in: fillRect)
                        }
                    } else {
                        let fontSize: CGFloat = userInitials == "YOU" ? 10 : 14
                        let youText = Text(userInitials)
                            .font(.system(size: fontSize, weight: .heavy))
                            .foregroundColor(NetworkColors.darkBlue)
                        context.draw(
                            context.resolve(youText),
                            at: center,
                            anchor: .center
                        )
                    }
                }

                // Invisible tap targets for ring-1 nodes
                let nodePositions = self.nodePositions(cx: cx, cy: cy, r1: r1)
                ForEach(Array(zip(nodePositions.indices, nodePositions)), id: \.0) { index, pos in
                    if index < contacts.count {
                        Circle()
                            .fill(Color.clear)
                            .contentShape(Circle())
                            .frame(width: 60, height: 60)
                            .position(pos.point)
                            .onTapGesture {
                                onSelectContact(contacts[index])
                            }
                    }
                }
            }
        }
        .frame(height: 420)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulsePhase = .pi * 2
            }
        }
        .task(id: userAvatarURL) {
            guard let url = userAvatarURL else {
                userAvatarImage = nil
                return
            }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                userAvatarImage = image
            }
        }
        .task(id: contacts.map(\.id)) {
            var loaded: [String: UIImage] = [:]
            for contact in contacts {
                guard let url = contact.profileAvatarURL else { continue }
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    loaded[contact.id] = image
                }
            }
            contactAvatarImages = loaded
        }
    }

    // MARK: - Node position calculation

    private struct NodePosition {
        let point: CGPoint
        let angle: Double
    }

    private func nodePositions(cx: CGFloat, cy: CGFloat, r1: CGFloat) -> [NodePosition] {
        let count = contacts.count
        guard count > 0 else { return [] }

        let angleStep = (2 * Double.pi) / Double(count)

        return (0..<count).map { i in
            let angle = Double(i) * angleStep - Double.pi / 2
            let x = cx + CGFloat(cos(angle)) * r1
            let y = cy + CGFloat(sin(angle)) * r1
            return NodePosition(point: CGPoint(x: x, y: y), angle: angle)
        }
    }

    private func aspectFillRect(imageSize: CGSize, in target: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return target }
        let scale = max(target.width / imageSize.width, target.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        return CGRect(
            x: target.midX - w / 2,
            y: target.midY - h / 2,
            width: w,
            height: h
        )
    }

    private func secondDegreePositions(around parent: CGPoint, parentAngle: Double, count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }
        let spread: Double = count == 1 ? 0 : min(Double.pi * 0.6, Double(count - 1) * 0.35)
        let startAngle = parentAngle - spread / 2

        return (0..<count).map { i in
            let angle = count == 1 ? parentAngle : startAngle + spread * Double(i) / Double(count - 1)
            let x = parent.x + CGFloat(cos(angle)) * dotSpreadRadius
            let y = parent.y + CGFloat(sin(angle)) * dotSpreadRadius
            return CGPoint(x: x, y: y)
        }
    }
}
