import Foundation

public enum ESPNClientError: Error {
    case badStatus(URL, Int)
}

/// Fetches everything one refresh needs from ESPN's public site API.
public struct ESPNClient: Sendable {
    static let base = "https://site.api.espn.com/apis/site/v2/sports/basketball"
    static let timeout: TimeInterval = 10

    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Scoreboard for the Eastern calendar day containing `day` (ESPN's `dates` are Eastern days).
    public static func scoreboardURL(_ league: League, day: Date) -> URL {
        let c = Calendar.eastern.dateComponents([.year, .month, .day], from: day)
        let stamp = String(format: "%04d%02d%02d", c.year!, c.month!, c.day!)
        return URL(string: "\(base)/\(league.rawValue)/scoreboard?groups=50&limit=400&dates=\(stamp)")!
    }

    public static func scheduleURL(_ league: League) -> URL {
        URL(string: "\(base)/\(league.rawValue)/teams/\(BigGames.uconnID)/schedule")!
    }

    /// Men's scoreboards for today-2 … today+7, both UConn schedules and today's women's scoreboard,
    /// fetched concurrently. Throws if any request fails, so a refresh is all-or-nothing.
    public func fetchInputs(now: Date) async throws -> BoardInputs {
        let cal = Calendar.eastern
        let today = cal.startOfDay(for: now)
        let days = (-BoardBuilder.latestDays...BoardBuilder.comingUpDays).map {
            cal.date(byAdding: .day, value: $0, to: today)!
        }

        async let menSchedule = data(Self.scheduleURL(.men))
        async let womenSchedule = data(Self.scheduleURL(.women))
        async let womenToday = data(Self.scoreboardURL(.women, day: today))
        let menDays = try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            for (i, day) in days.enumerated() {
                group.addTask { (i, try await data(Self.scoreboardURL(.men, day: day))) }
            }
            var out = [(Int, Data)]()
            for try await item in group { out.append(item) }
            return out.sorted { $0.0 < $1.0 }.map(\.1)
        }

        let men = try ESPNDecoder.schedule(await menSchedule, league: .men)
        let women = try ESPNDecoder.schedule(await womenSchedule, league: .women)
        return BoardInputs(
            menScoreboard: try menDays.flatMap { try ESPNDecoder.scoreboard($0, league: .men) },
            menSchedule: men.games, menRecord: men.record,
            womenSchedule: women.games,
            womenToday: try ESPNDecoder.scoreboard(await womenToday, league: .women)
        )
    }

    func data(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.timeout
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw ESPNClientError.badStatus(url, status) }
        return data
    }
}
