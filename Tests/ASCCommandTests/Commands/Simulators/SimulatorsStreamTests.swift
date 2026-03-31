import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct SimulatorsStreamTests {

    @Test func `stream command parses udid and port options`() throws {
        let cmd = try SimulatorsStream.parse(["--udid", "ABCD-1234"])
        #expect(cmd.udid == "ABCD-1234")
        #expect(cmd.port == 8425)
    }

    @Test func `stream command parses custom port`() throws {
        let cmd = try SimulatorsStream.parse(["--udid", "ABCD-1234", "--port", "9000"])
        #expect(cmd.udid == "ABCD-1234")
        #expect(cmd.port == 9000)
    }

    @Test func `stream command parses fps option`() throws {
        let cmd = try SimulatorsStream.parse(["--udid", "ABCD-1234", "--fps", "10"])
        #expect(cmd.fps == 10)
    }

    @Test func `stream command defaults fps to 5`() throws {
        let cmd = try SimulatorsStream.parse(["--udid", "ABCD-1234"])
        #expect(cmd.fps == 5)
    }

    @Test func `stream command works without udid for device picker mode`() throws {
        let cmd = try SimulatorsStream.parse([])
        #expect(cmd.udid == nil)
        #expect(cmd.port == 8425)
    }
}
