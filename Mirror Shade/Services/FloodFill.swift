//
//  FloodFill.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import UIKit

enum FloodFill {

    // MARK: - Configuration

    private static let bytesPerPixel = 4

    // MARK: - Public API

    static func apply(
        to image: UIImage,
        at point: CGPoint,
        color: UIColor,
        tolerance: Int = 20
    ) -> UIImage? {

        guard let cgImage = image.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        guard width > 0, height > 0 else {
            return nil
        }

        let x = Int(point.x)
        let y = Int(point.y)

        guard x >= 0,
            y >= 0,
            x < width,
            y < height
        else {
            return nil
        }

        let bytesPerRow = width * bytesPerPixel
        let pixelCount = width * height

        // MARK: - Bitmap

        var pixels = [UInt8](
            repeating: 0,
            count: pixelCount * bytesPerPixel
        )

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let bitmapInfo =
            CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue

        return pixels.withUnsafeMutableBytes { buffer in

            guard let baseAddress = buffer.baseAddress,
                let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                )
            else {
                return nil
            }

            context.interpolationQuality = .none
            context.setBlendMode(.copy)

            context.draw(
                cgImage,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height
                )
            )

            guard
                let data = buffer.baseAddress?
                    .assumingMemoryBound(to: UInt8.self)
            else {
                return nil
            }

            // MARK: - Colors

            let startIndex = (y * width + x) * bytesPerPixel

            let target = PixelColor(
                red: data[startIndex],
                green: data[startIndex + 1],
                blue: data[startIndex + 2],
                alpha: data[startIndex + 3]
            )

            let replacement = PixelColor(color)

            if target == replacement {
                return image
            }

            let threshold = max(0, min(tolerance, 255))

            // MARK: - Scanline Fill

            var visited = [UInt8](
                repeating: 0,
                count: pixelCount
            )

            var stack: [Int] = []
            stack.reserveCapacity(min(width * 2, 8192))

            stack.append(y * width + x)

            func matches(_ position: Int) -> Bool {
                guard visited[position] == 0 else {
                    return false
                }

                let offset = position * bytesPerPixel

                return target.matches(
                    red: data[offset],
                    green: data[offset + 1],
                    blue: data[offset + 2],
                    alpha: data[offset + 3],
                    tolerance: threshold
                )
            }

            func paint(_ position: Int) {
                let offset = position * bytesPerPixel

                data[offset] = replacement.red
                data[offset + 1] = replacement.green
                data[offset + 2] = replacement.blue
                data[offset + 3] = replacement.alpha

                visited[position] = 1
            }

            while let position = stack.popLast() {

                guard matches(position) else {
                    continue
                }

                let row = position / width
                let rowStart = row * width
                let rowEnd = rowStart + width

                // Find the left boundary.

                var left = position

                while left > rowStart,
                    matches(left - 1)
                {
                    left -= 1
                }

                // Fill horizontally.

                var current = left

                while current < rowEnd,
                    matches(current)
                {

                    paint(current)

                    current += 1
                }

                let right = current

                // Find connected spans in adjacent rows.

                for adjacentRow in [row - 1, row + 1] {

                    guard adjacentRow >= 0,
                        adjacentRow < height
                    else {
                        continue
                    }

                    let adjacentStart = adjacentRow * width

                    var column = left - rowStart
                    let endColumn = right - rowStart

                    while column < endColumn {

                        let candidate = adjacentStart + column

                        if matches(candidate) {

                            stack.append(candidate)

                            // Skip the rest of this span.

                            column += 1

                            while column < endColumn,
                                matches(adjacentStart + column)
                            {
                                column += 1
                            }

                        } else {
                            column += 1
                        }
                    }
                }
            }

            // MARK: - Result

            guard let result = context.makeImage() else {
                return nil
            }

            return UIImage(
                cgImage: result,
                scale: 1,
                orientation: .up
            )
        }
    }
}

// MARK: - Pixel Color

private struct PixelColor: Equatable {

    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    init(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ color: UIColor) {

        let resolved = color.resolvedColor(
            with: UITraitCollection.current
        )

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        if !resolved.getRed(
            &r,
            green: &g,
            blue: &b,
            alpha: &a
        ) {
            r = 0
            g = 0
            b = 0
            a = 1
        }

        let red = Self.byte(r)
        let green = Self.byte(g)
        let blue = Self.byte(b)
        let alpha = Self.byte(a)

        // Premultiplied alpha

        self.red = Self.premultiply(red, alpha)
        self.green = Self.premultiply(green, alpha)
        self.blue = Self.premultiply(blue, alpha)
        self.alpha = alpha
    }

    func matches(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        alpha: UInt8,
        tolerance: Int
    ) -> Bool {

        // Fully transparent pixels have no visible RGB color.

        if self.alpha == 0 && alpha == 0 {
            return true
        }

        return abs(Int(self.red) - Int(red)) <= tolerance
            && abs(Int(self.green) - Int(green)) <= tolerance
            && abs(Int(self.blue) - Int(blue)) <= tolerance
            && abs(Int(self.alpha) - Int(alpha)) <= tolerance
    }

    private static func byte(_ value: CGFloat) -> UInt8 {
        UInt8(
            (max(0, min(1, value)) * 255).rounded()
        )
    }

    private static func premultiply(
        _ channel: UInt8,
        _ alpha: UInt8
    ) -> UInt8 {
        UInt8(
            (Int(channel) * Int(alpha) + 127) / 255
        )
    }
}
