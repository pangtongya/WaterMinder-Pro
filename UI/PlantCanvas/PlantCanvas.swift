// PlantCanvas.swift
// ⭐ 植物绘制引擎 —— 用 SwiftUI Canvas 程序化绘制，不依赖图片
//
// 核心理念：植物形态随"成长阶段"和"健康度"连续变化。
//   - 茎高度随阶段增长
//   - 叶片数量随阶段增加
//   - 花朵大小随阶段绽放
//   - 颜色饱和度、叶子下垂角度随健康度变化（蔫了→灰绿下垂）
//
// 先用向日葵打通全链路，再扩展其他品种的渲染分支。

import SwiftUI

struct PlantCanvas: View {
    let state: PlantVisualState

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let centerX = w / 2
            let soilY = h * 0.82           // 土壤顶部 Y 坐标
            let maxHeight = h * 0.62       // 植物最大高度

            // 1. 花盆 + 土壤（底部）
            drawPot(context: &context, centerX: centerX, soilY: soilY, potHeight: h * 0.18)

            // 2. 茎 + 叶（中部）
            let stemHeight = maxHeight * state.stemRatio
            drawStemAndLeaves(
                context: &context,
                baseX: centerX,
                baseY: soilY,
                height: stemHeight
            )

            // 3. 花朵（顶部，仅 blooming/harvestable）
            if state.hasFlower {
                drawFlower(
                    context: &context,
                    centerX: centerX,
                    topY: soilY - stemHeight
                )
            }
        }
    }

    // MARK: - 花盆 + 土壤

    private func drawPot(context: inout GraphicsContext, centerX: Double, soilY: Double, potHeight: Double) {
        let potWidth = potHeight * 1.4
        let rimHeight = potHeight * 0.18

        // 花盆主体（梯形）
        let potPath = Path { p in
            p.move(to: CGPoint(x: centerX - potWidth / 2, y: soilY))
            p.addLine(to: CGPoint(x: centerX - potWidth / 2 * 0.8, y: soilY + potHeight))
            p.addLine(to: CGPoint(x: centerX + potWidth / 2 * 0.8, y: soilY + potHeight))
            p.addLine(to: CGPoint(x: centerX + potWidth / 2, y: soilY))
            p.closeSubpath()
        }
        context.fill(potPath, with: .color(Color.bloomSoil.opacity(0.85)))

        // 花盆口沿（深色横条）
        let rimPath = Path(CGRect(
            x: centerX - potWidth / 2,
            y: soilY - rimHeight / 2,
            width: potWidth,
            height: rimHeight
        ))
        context.fill(rimPath, with: .color(Color.bloomSoil))

        // 土壤（顶部深褐椭圆）
        let soilRect = CGRect(
            x: centerX - potWidth / 2 + 4,
            y: soilY - 6,
            width: potWidth - 8,
            height: 12
        )
        context.fill(
            Path(ellipseIn: soilRect),
            with: .color(Color(red: 0.36, green: 0.25, blue: 0.15))
        )
    }

    // MARK: - 茎 + 叶

    private func drawStemAndLeaves(
        context: inout GraphicsContext,
        baseX: Double,
        baseY: Double,
        height: Double
    ) {
        guard height > 8 else {
            // 种子阶段：画一个小芽点
            let seedRect = CGRect(x: baseX - 6, y: baseY - 8, width: 12, height: 10)
            context.fill(Path(ellipseIn: seedRect), with: .color(Color.bloomLeaf))
            return
        }

        // 摇摆：顶部 X 偏移
        let sway = sin(state.time) * state.swayAmplitude * height

        // 茎（贝塞尔曲线，带轻微弯曲）
        let stemColor = Color.bloomLeaf
            .adjusted(saturation: state.saturation, brightness: state.leafBrightness - 0.15)

        let stemPath = Path { p in
            p.move(to: CGPoint(x: baseX, y: baseY))
            p.addQuadCurve(
                to: CGPoint(x: baseX + sway, y: baseY - height),
                control: CGPoint(x: baseX + sway * 0.3, y: baseY - height * 0.5)
            )
        }
        context.stroke(
            stemPath,
            with: .color(stemColor),
            style: StrokeStyle(lineWidth: max(3, height * 0.04), lineCap: .round)
        )

        // 叶子（沿茎对称分布）
        let leafColor = Color.bloomLeaf
            .adjusted(saturation: state.saturation, brightness: state.leafBrightness)

        let count = min(state.leafCount, 6)  // 视觉上限制最多 6 片
        for i in 0..<count {
            let t = 0.2 + (Double(i) + 0.5) / Double(count) * 0.7   // 沿茎的位置 0.2–0.9
            let stemX = baseX + sway * t
            let stemY = baseY - height * t
            let side: Double = (i % 2 == 0) ? -1 : 1                // 左右交替
            drawLeaf(
                context: &context,
                at: CGPoint(x: stemX, y: stemY),
                side: side,
                color: leafColor,
                size: 14 + height * 0.05
            )
        }
    }

    private func drawLeaf(
        context: inout GraphicsContext,
        at point: CGPoint,
        side: Double,
        color: Color,
        size: Double
    ) {
        // 下垂角度：蔫了叶子朝下
        let baseAngle = side > 0 ? -0.5 : 0.5      // 正常约 ±28°
        let angle = baseAngle + (side > 0 ? state.droopAngle : -state.droopAngle)

        var leafContext = context
        leafContext.translateBy(x: point.x, y: point.y)
        leafContext.rotate(by: .radians(angle))

        let leafPath = Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addQuadCurve(
                to: CGPoint(x: side * size, y: 0),
                control: CGPoint(x: side * size * 0.5, y: -size * 0.4)
            )
            p.addQuadCurve(
                to: CGPoint(x: 0, y: 0),
                control: CGPoint(x: side * size * 0.5, y: size * 0.4)
            )
        }
        leafContext.fill(leafPath, with: .color(color))
    }

    // MARK: - 花朵（按品种形态分支渲染）

    private func drawFlower(context: inout GraphicsContext, centerX: Double, topY: Double) {
        let radius = 32 * state.flowerSize   // 基础半径
        let petalColor = state.species.flowerColor
            .adjusted(saturation: state.saturation)
        let petalDark = state.species.flowerColor
            .adjusted(saturation: state.saturation, brightness: 0.75)
        let centerColor = state.species.flowerCenterColor

        var fc = context
        fc.translateBy(x: centerX, y: topY)
        fc.rotate(by: .radians(state.time * 0.1))

        switch state.species.petalShape {
        case .pointed:
            drawPointedFlower(&fc, radius: radius, count: state.species.petalCount,
                              color: petalColor, dark: petalDark, center: centerColor)
        case .round:
            drawRoundFlower(&fc, radius: radius, count: state.species.petalCount,
                            color: petalColor, center: centerColor)
        case .cluster:
            drawClusterFlower(&fc, radius: radius, count: state.species.petalCount,
                              color: petalColor, center: centerColor)
        case .fan:
            drawSucculentRosette(&fc, radius: radius, color: petalColor, center: centerColor)
        }
    }

    // MARK: 尖瓣花（向日葵 / 玫瑰）—— 长水滴花瓣，外层亮内层深

    private func drawPointedFlower(
        _ context: inout GraphicsContext,
        radius: Double, count: Int,
        color: Color, dark: Color, center: Color
    ) {
        // 外层花瓣
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi
            var pc = context
            pc.rotate(by: .radians(angle))

            let petalPath = Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(
                    to: CGPoint(x: radius, y: 0),
                    control: CGPoint(x: radius * 0.45, y: -radius * 0.28)
                )
                p.addQuadCurve(
                    to: CGPoint(x: 0, y: 0),
                    control: CGPoint(x: radius * 0.45, y: radius * 0.28)
                )
            }
            pc.fill(petalPath, with: .color(color))
        }

        // 内层小花瓣（深色，制造层次）
        let innerCount = max(count - 2, 5)
        for i in 0..<innerCount {
            let angle = (Double(i) / Double(innerCount)) * 2 * .pi + .pi / Double(innerCount)
            var pc = context
            pc.rotate(by: .radians(angle))

            let innerPath = Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(
                    to: CGPoint(x: radius * 0.6, y: 0),
                    control: CGPoint(x: radius * 0.3, y: -radius * 0.18)
                )
                p.addQuadCurve(
                    to: CGPoint(x: 0, y: 0),
                    control: CGPoint(x: radius * 0.3, y: radius * 0.18)
                )
            }
            pc.fill(innerPath, with: .color(dark))
        }

        // 花心
        let cr = CGRect(x: -radius * 0.3, y: -radius * 0.3, width: radius * 0.6, height: radius * 0.6)
        context.fill(Path(ellipseIn: cr), with: .color(center))
    }

    // MARK: 圆瓣花（薄荷 / 郁金香）—— 宽短椭圆花瓣

    private func drawRoundFlower(
        _ context: inout GraphicsContext,
        radius: Double, count: Int,
        color: Color, center: Color
    ) {
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi
            var pc = context
            pc.rotate(by: .radians(angle))

            let petalRect = CGRect(
                x: radius * 0.2, y: -radius * 0.32,
                width: radius * 0.85, height: radius * 0.64
            )
            pc.fill(Path(ellipseIn: petalRect), with: .color(color))
        }

        // 花心
        let cr = CGRect(x: -radius * 0.22, y: -radius * 0.22, width: radius * 0.44, height: radius * 0.44)
        context.fill(Path(ellipseIn: cr), with: .color(center))
    }

    // MARK: 簇状花（樱花 / 薰衣草）—— 多个小花簇组成一朵

    private func drawClusterFlower(
        _ context: inout GraphicsContext,
        radius: Double, count: Int,
        color: Color, center: Color
    ) {
        // 外圈分布若干小花，每朵 5 个小瓣
        let clusterCount = min(count, 7)
        for i in 0..<clusterCount {
            let angle = (Double(i) / Double(clusterCount)) * 2 * .pi
            let cx = cos(angle) * radius * 0.45
            let cy = sin(angle) * radius * 0.45
            var cc = context
            cc.translateBy(x: cx, y: cy)

            // 单朵小花：5 个小瓣
            let miniR = radius * 0.3
            for j in 0..<5 {
                let a = (Double(j) / 5) * 2 * .pi
                var mc = cc
                mc.rotate(by: .radians(a))
                let r = CGRect(x: miniR * 0.2, y: -miniR * 0.35,
                               width: miniR, height: miniR * 0.7)
                mc.fill(Path(ellipseIn: r), with: .color(color))
            }
        }

        // 中心点缀
        let cr = CGRect(x: -radius * 0.15, y: -radius * 0.15, width: radius * 0.3, height: radius * 0.3)
        context.fill(Path(ellipseIn: cr), with: .color(center))
    }

    // MARK: 多肉莲座（succulent）—— 从中心向外辐射的肥厚叶片

    private func drawSucculentRosette(
        _ context: inout GraphicsContext,
        radius: Double,
        color: Color, center: Color
    ) {
        let layers = 3
        for layer in 0..<layers {
            let layerCount = 6 + layer * 2
            let layerR = radius * (0.4 + Double(layer) * 0.3)
            let alpha = 1.0 - Double(layer) * 0.15

            for i in 0..<layerCount {
                let angle = (Double(i) / Double(layerCount)) * 2 * .pi + Double(layer) * 0.3
                var pc = context
                pc.rotate(by: .radians(angle))

                // 肥厚叶片：三角形
                let leafPath = Path { p in
                    p.move(to: CGPoint(x: 0, y: 0))
                    p.addQuadCurve(
                        to: CGPoint(x: layerR, y: 0),
                        control: CGPoint(x: layerR * 0.5, y: -layerR * 0.25)
                    )
                    p.addQuadCurve(
                        to: CGPoint(x: 0, y: 0),
                        control: CGPoint(x: layerR * 0.5, y: layerR * 0.25)
                    )
                }
                pc.fill(leafPath, with: .color(color.opacity(alpha)))
            }
        }

        // 中心
        let cr = CGRect(x: -radius * 0.18, y: -radius * 0.18, width: radius * 0.36, height: radius * 0.36)
        context.fill(Path(ellipseIn: cr), with: .color(center))
    }
}
