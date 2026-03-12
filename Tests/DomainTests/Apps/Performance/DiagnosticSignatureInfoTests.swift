import Foundation
import Testing
@testable import Domain

@Suite("DiagnosticSignatureInfo")
struct DiagnosticSignatureInfoTests {

    @Test func `signature carries build id`() {
        let sig = MockRepositoryFactory.makeDiagnosticSignatureInfo(
            id: "sig-1",
            buildId: "build-1",
            diagnosticType: .hangs,
            signature: "main thread hang in -[UIView layoutSubviews]",
            weight: 45.2
        )
        #expect(sig.id == "sig-1")
        #expect(sig.buildId == "build-1")
        #expect(sig.diagnosticType == .hangs)
        #expect(sig.signature == "main thread hang in -[UIView layoutSubviews]")
        #expect(sig.weight == 45.2)
    }

    @Test func `all diagnostic types have correct raw values`() {
        #expect(DiagnosticType.diskWrites.rawValue == "DISK_WRITES")
        #expect(DiagnosticType.hangs.rawValue == "HANGS")
        #expect(DiagnosticType.launches.rawValue == "LAUNCHES")
    }

    @Test func `signature affordances include list logs and list signatures`() {
        let sig = MockRepositoryFactory.makeDiagnosticSignatureInfo(
            id: "sig-1",
            buildId: "build-1"
        )
        #expect(sig.affordances["listLogs"] == "asc diagnostic-logs list --signature-id sig-1")
        #expect(sig.affordances["listSignatures"] == "asc diagnostics list --build-id build-1")
    }

    @Test func `signature encodes nil insight direction as omitted`() throws {
        let sig = MockRepositoryFactory.makeDiagnosticSignatureInfo(insightDirection: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(sig)
        let json = String(data: data, encoding: .utf8)!
        #expect(!json.contains("insightDirection"))
    }

    @Test func `signature encodes non-nil insight direction`() throws {
        let sig = MockRepositoryFactory.makeDiagnosticSignatureInfo(insightDirection: "UP")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(sig)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("\"insightDirection\":\"UP\""))
    }
}
