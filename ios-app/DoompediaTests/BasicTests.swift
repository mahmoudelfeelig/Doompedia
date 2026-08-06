import XCTest
import UIKit
@testable import Doompedia

final class BasicTests: XCTestCase {
    func testNormalizeSearchCompactsWhitespaceAndCase() {
        XCTAssertEqual(normalizeSearch("  Alan   Turing "), "alan turing")
    }

    func testEditDistanceAtMostOne() {
        XCTAssertTrue(editDistanceAtMostOne("science", "sciense"))
        XCTAssertTrue(editDistanceAtMostOne("history", "history"))
        XCTAssertFalse(editDistanceAtMostOne("technology", "biology"))
    }

    func testBrandLogoIsBundled() {
        XCTAssertNotNil(UIImage(named: "elephant-logo"))
    }

    func testFeedCandidatesCanBeLoadedAndPaged() throws {
        let filename = "doompedia-feed-test-\(UUID().uuidString).sqlite"
        var store: SQLiteStore? = try SQLiteStore(filename: filename)
        defer {
            store = nil
            removeTestDatabase(filename: filename)
        }

        try store?.upsertSeedRows([
            SeedRow(
                page_id: 101,
                lang: "en",
                title: "Ada Lovelace",
                summary: "English mathematician and early computing pioneer.",
                wiki_url: "https://en.wikipedia.org/wiki/Ada_Lovelace",
                topic_key: "science",
                quality_score: 0.9,
                is_disambiguation: false,
                source_rev_id: 1,
                updated_at: "2026-08-06T00:00:00Z",
                aliases: []
            ),
            SeedRow(
                page_id: 102,
                lang: "en",
                title: "Grace Hopper",
                summary: "American computer scientist and United States Navy rear admiral.",
                wiki_url: "https://en.wikipedia.org/wiki/Grace_Hopper",
                topic_key: "science",
                quality_score: 0.8,
                is_disambiguation: false,
                source_rev_id: 1,
                updated_at: "2026-08-06T00:00:00Z",
                aliases: []
            ),
        ])

        XCTAssertEqual(try store?.feedCandidates(language: "en", offset: 0, limit: 1).map(\.title), ["Ada Lovelace"])
        XCTAssertEqual(try store?.feedCandidates(language: "en", offset: 1, limit: 1).map(\.title), ["Grace Hopper"])
    }

    private func removeTestDatabase(filename: String) {
        guard let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }

        let baseURL = directory.appendingPathComponent(filename)
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: baseURL.path + suffix))
        }
    }
}
