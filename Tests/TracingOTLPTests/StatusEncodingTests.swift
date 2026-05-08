// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter
import Bytes

@Suite("Status.Code raw values")
struct StatusCodeTests {
    @Test("Status.Code raw values match proto: unset=0, ok=1, error=2")
    func rawValues() {
        #expect(OTLP.Status.Code.unset.rawValue == 0)
        #expect(OTLP.Status.Code.ok.rawValue == 1)
        #expect(OTLP.Status.Code.error.rawValue == 2)
    }
}

@Suite("Status encoding")
struct StatusEncodingTests {
    @Test("empty Status (code=unset, message=\"\") encodes to empty")
    func empty() {
        let bytes = EncodeTraces.encodeStatus(OTLP.Status())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Status with code=.ok only")
    func okOnly() {
        let s = OTLP.Status(code: .ok)
        let bytes = EncodeTraces.encodeStatus(s)
        // field 3 enum, tag (3<<3)|0 = 0x18; varint 1
        #expect(Array(bytes.storage) == [0x18, 0x01])
    }

    @Test("Status with code=.error and message=\"db timeout\"")
    func errorWithMessage() {
        let s = OTLP.Status(message: "db timeout", code: .error)
        let bytes = EncodeTraces.encodeStatus(s)
        var expected: [UInt8] = [0x12, 0x0A]
        expected.append(contentsOf: Array("db timeout".utf8))
        expected.append(contentsOf: [0x18, 0x02])
        #expect(Array(bytes.storage) == expected)
    }
}
