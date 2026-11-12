import AppKit
import Foundation
import Testing
@testable import CBBCore

@Test func scoreboardURLUsesEasternDay() {
    let u = ESPNClient.scoreboardURL(.men, day: ESPNDecoder.parseDate("2026-11-13T03:30Z")!)  // 10:30 PM ET Nov 12
    #expect(u.absoluteString == "https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard?groups=50&limit=400&dates=20261112")
    #expect(ESPNClient.scheduleURL(.women).absoluteString == "https://site.api.espn.com/apis/site/v2/sports/basketball/womens-college-basketball/teams/41/schedule")
}

@Test func snapshotRoundTrips() throws {
    let dir = FileManager.default.temporaryDirectory.appending(path: "cbb-test-\(UUID())")
    defer { try? FileManager.default.removeItem(at: dir) }
    let store = SnapshotStore(directory: dir)
    #expect(store.load() == nil)
    try store.save(Snapshot(inputs: inputsFromFixtures(), fetchedAt: et("2026-11-12 15:00")))
    #expect(store.load()?.inputs.menRecord == "3-0")
    #expect(store.load()?.fetchedAt == et("2026-11-12 15:00"))
}

@Test func staleAfter30Minutes() {
    let s = Snapshot(inputs: inputsFromFixtures(), fetchedAt: et("2026-11-12 15:00"))
    #expect(!SnapshotStore.isStale(s, now: et("2026-11-12 15:29")))
    #expect(SnapshotStore.isStale(s, now: et("2026-11-12 15:31")))
}

/// These share StubProtocol's global state, so they run one at a time.
@Suite(.serialized) struct NetworkTests {
    @Test func fetchFailureThrows() async {
        await #expect(throws: (any Error).self) {
            try await ESPNClient(session: stubSession(status: 500)).fetchInputs(now: et("2026-11-12 15:00"))
        }
    }

    @Test func fetchDecodesEveryRequest() async throws {
        let inputs = try await ESPNClient(session: stubSession(status: 200)).fetchInputs(now: et("2026-11-12 15:00"))
        #expect(inputs.menRecord == "3-0")                      // schedule fixture served for schedule URLs
        #expect(inputs.menScoreboard.contains { $0.involves("41") })
        #expect(StubProtocol.requestCount() == 13)               // 10 men's days, 2 schedules, women's today
    }

    @Test func logoCacheSkipsFailuresAndKeepsHits() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "cbb-test-\(UUID())")
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = SnapshotStore(directory: dir)
        await store.cacheLogos(for: ["41"], session: stubSession(status: 500))
        #expect(store.logo("41") == nil)
        await store.cacheLogos(for: ["41"], session: stubSession(status: 200))
        let data = try #require(store.logo("41"))
        let image = try #require(NSBitmapImageRep(data: data))
        #expect(image.pixelsWide == 64 && image.pixelsHigh == 64)
    }
}

// MARK: - URLProtocol stub

final class StubProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var count = 0
    static let lock = NSLock()

    static func requestCount() -> Int { lock.withLock { count } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let status = Self.lock.withLock { Self.count += 1; return Self.status }
        let body: Data
        if status != 200 {
            body = Data()
        } else if url.path.hasSuffix("/schedule") {
            body = fixture(url.path.contains("womens") ? "women_schedule_41" : "men_schedule_41")
        } else if url.path.hasSuffix(".png") {
            body = tinyPNG()
        } else {
            body = fixture("men_scoreboard_20261113")
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

func stubSession(status: Int) -> URLSession {
    StubProtocol.lock.withLock { StubProtocol.status = status; StubProtocol.count = 0 }
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubProtocol.self]
    return URLSession(configuration: config)
}

func tinyPNG() -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 200, pixelsHigh: 200, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    return rep.representation(using: .png, properties: [:])!
}
