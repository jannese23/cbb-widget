import Foundation
import ImageIO
import UniformTypeIdentifiers

/// The last good fetch. Boards are rebuilt from it for any moment, so ticket states stay right offline.
public struct Snapshot: Codable, Sendable {
    public let inputs: BoardInputs
    public let fetchedAt: Date

    public init(inputs: BoardInputs, fetchedAt: Date) {
        self.inputs = inputs
        self.fetchedAt = fetchedAt
    }
}

/// On-disk cache of the last snapshot and of team logos, resized for the widget.
public final class SnapshotStore: @unchecked Sendable {
    static let staleAfter: TimeInterval = 30 * 60
    static let logoPixels = 64

    let directory: URL
    private var snapshotURL: URL { directory.appending(path: "snapshot.json") }
    private var logosURL: URL { directory.appending(path: "logos") }

    public init(directory: URL) {
        self.directory = directory
    }

    public func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    public func save(_ s: Snapshot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(s).write(to: snapshotURL, options: .atomic)
    }

    public static func isStale(_ s: Snapshot, now: Date) -> Bool {
        now.timeIntervalSince(s.fetchedAt) > staleAfter
    }

    public static func logoURL(_ teamID: String) -> URL {
        URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500-dark/\(teamID).png")!
    }

    public func logo(_ teamID: String) -> Data? {
        try? Data(contentsOf: logosURL.appending(path: "\(teamID).png"))
    }

    /// Downloads and caches any logos not already on disk. Failures are ignored: the view falls back
    /// to the team abbreviation.
    public func cacheLogos(for teamIDs: Set<String>, session: URLSession) async {
        try? FileManager.default.createDirectory(at: logosURL, withIntermediateDirectories: true)
        let missing = teamIDs.filter { logo($0) == nil }
        await withTaskGroup(of: Void.self) { group in
            for id in missing {
                group.addTask { [logosURL] in
                    guard let (data, response) = try? await session.data(from: Self.logoURL(id)),
                          (response as? HTTPURLResponse)?.statusCode == 200,
                          let png = Self.resized(data, to: Self.logoPixels)
                    else { return }
                    try? png.write(to: logosURL.appending(path: "\(id).png"), options: .atomic)
                }
            }
        }
    }

    static func resized(_ data: Data, to pixels: Int) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
        guard let scaled = ctx.makeImage() else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, scaled, nil)
        return CGImageDestinationFinalize(dest) ? out as Data : nil
    }
}
