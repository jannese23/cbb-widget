import Foundation

public enum ESPNDecodingError: Error {
    case unexpectedShape
}

/// Turns ESPN site-API responses into `Game`s. Lenient per event: one malformed event is skipped,
/// only a response whose top level isn't recognisable throws.
public enum ESPNDecoder {
    public static func scoreboard(_ data: Data, league: League) throws -> [Game] {
        let events = try topLevel(data)["events"] as? [[String: Any]] ?? []
        return events.compactMap { game(from: $0, league: league) }
    }

    public static func schedule(_ data: Data, league: League) throws -> (record: String?, games: [Game]) {
        let root = try topLevel(data)
        let record = (root["team"] as? [String: Any])?["recordSummary"] as? String
        let events = root["events"] as? [[String: Any]] ?? []
        return (record, events.compactMap { game(from: $0, league: league) })
    }

    public static func parseDate(_ s: String) -> Date? {
        for formatter in formatters {
            if let d = formatter.date(from: s) { return d }
        }
        return nil
    }

    private static let formatters: [DateFormatter] = [
        "yyyy-MM-dd'T'HH:mmX", "yyyy-MM-dd'T'HH:mm:ssX",
    ].map { format in
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = format
        return f
    }

    private static func topLevel(_ data: Data) throws -> [String: Any] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ESPNDecodingError.unexpectedShape
        }
        return root
    }

    private static let postponedNames: Set<String> = [
        "STATUS_POSTPONED", "STATUS_CANCELED", "STATUS_CANCELLED", "STATUS_SUSPENDED", "STATUS_FORFEIT",
    ]

    private static func game(from event: [String: Any], league: League) -> Game? {
        guard let id = event["id"] as? String,
              let dateString = event["date"] as? String, let start = parseDate(dateString),
              let comp = (event["competitions"] as? [[String: Any]])?.first,
              let rawCompetitors = comp["competitors"] as? [[String: Any]], rawCompetitors.count == 2
        else { return nil }
        let competitors = rawCompetitors.compactMap(competitor(from:))
        guard competitors.count == 2,
              let home = competitors.first(where: \.isHome) ?? competitors.first,
              let away = competitors.first(where: { $0 != home })
        else { return nil }

        let status = comp["status"] as? [String: Any] ?? event["status"] as? [String: Any] ?? [:]
        let type = status["type"] as? [String: Any] ?? [:]
        let state: GameState
        if postponedNames.contains(type["name"] as? String ?? "") {
            state = .postponed
        } else {
            switch type["state"] as? String {
            case "in": state = .live
            case "post": state = (type["completed"] as? Bool ?? true) ? .final : .postponed
            default: state = .pre
            }
        }

        let link = (event["links"] as? [[String: Any]])?
            .compactMap { $0["href"] as? String }
            .first { $0.hasPrefix("https://") }
            .flatMap(URL.init(string:))

        // Scoreboards report "0"–"0" before tip; a game that hasn't started has no score.
        let unscored = state == .pre || state == .postponed
        let (h, a) = unscored ? (home.withoutScore, away.withoutScore) : (home, away)

        return Game(
            id: id, league: league, start: start, state: state,
            period: status["period"] as? Int ?? 0,
            statusText: type["shortDetail"] as? String ?? "",
            venue: (comp["venue"] as? [String: Any])?["fullName"] as? String,
            home: h, away: a, link: link
        )
    }

    private static func competitor(from raw: [String: Any]) -> Competitor? {
        guard let team = raw["team"] as? [String: Any], let id = team["id"] as? String else { return nil }
        let rank = (raw["curatedRank"] as? [String: Any])?["current"] as? Int
        return Competitor(
            team: Team(
                id: id,
                abbreviation: team["abbreviation"] as? String ?? "",
                location: team["location"] as? String ?? team["displayName"] as? String ?? ""
            ),
            rank: rank.flatMap { (1...25).contains($0) ? $0 : nil },
            score: score(raw["score"]),
            isHome: (raw["homeAway"] as? String) == "home"
        )
    }

    /// Scoreboards send "83"; team schedules send {"value": 83.0, "displayValue": "83"} or nothing.
    private static func score(_ raw: Any?) -> Int? {
        if let s = raw as? String { return Int(s) }
        if let obj = raw as? [String: Any] {
            if let s = obj["displayValue"] as? String { return Int(s) }
            if let v = obj["value"] as? Double { return Int(v) }
        }
        return nil
    }
}

private extension Competitor {
    var withoutScore: Competitor { Competitor(team: team, rank: rank, score: nil, isHome: isHome) }
}
