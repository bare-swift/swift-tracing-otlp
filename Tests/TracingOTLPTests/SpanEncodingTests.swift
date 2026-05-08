// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter
import Bytes

@Suite("Span encoding (16 fields)")
struct SpanEncodingTests {
    @Test("empty Span encodes to empty bytes (all fields default)")
    func empty() {
        let bytes = EncodeTraces.encodeSpan(OTLP.Span())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Span with name=\"x\" only")
    func nameOnly() {
        var s = OTLP.Span()
        s.name = "x"
        let bytes = EncodeTraces.encodeSpan(s)
        // field 5 string "x": tag (5<<3)|2 = 0x2A, len 1, "x"
        #expect(Array(bytes.storage) == [0x2A, 0x01, 0x78])
    }

    @Test("Span with traceID + spanID")
    func ids() {
        var s = OTLP.Span()
        s.traceID = Bytes(repeating: 0xAB, count: 16)
        s.spanID = Bytes(repeating: 0xCD, count: 8)
        let bytes = EncodeTraces.encodeSpan(s)
        var expected: [UInt8] = [0x0A, 0x10]
        expected.append(contentsOf: Array(repeating: 0xAB, count: 16))
        expected.append(contentsOf: [0x12, 0x08])
        expected.append(contentsOf: Array(repeating: 0xCD, count: 8))
        #expect(Array(bytes.storage) == expected)
    }

    @Test("Span with kind=.server (field 6 enum)")
    func kindServer() {
        var s = OTLP.Span()
        s.kind = .server
        let bytes = EncodeTraces.encodeSpan(s)
        #expect(Array(bytes.storage) == [0x30, 0x02])
    }

    @Test("Span with start/end times (fields 7, 8)")
    func times() {
        var s = OTLP.Span()
        s.startTimeUnixNano = 1
        s.endTimeUnixNano = 2
        let bytes = EncodeTraces.encodeSpan(s)
        var expected: [UInt8] = [0x39, 0x01, 0, 0, 0, 0, 0, 0, 0]
        expected.append(contentsOf: [0x41, 0x02, 0, 0, 0, 0, 0, 0, 0])
        #expect(Array(bytes.storage) == expected)
    }

    @Test("Span with attributes (field 9)")
    func attributes() {
        var s = OTLP.Span()
        s.attributes = [OTLP.KeyValue(key: "k", value: .string("v"))]
        let bytes = EncodeTraces.encodeSpan(s)
        var expected: [UInt8] = [0x4A, 0x08]
        expected.append(contentsOf: [0x0A, 0x01, 0x6B, 0x12, 0x03, 0x0A, 0x01, 0x76])
        #expect(Array(bytes.storage) == expected)
    }

    @Test("Span with status field 15")
    func status() {
        var s = OTLP.Span()
        s.status = OTLP.Status(code: .ok)
        let bytes = EncodeTraces.encodeSpan(s)
        // Status inner = [0x18, 0x01] (2 bytes). field 15: tag 0x7A, len 2.
        #expect(Array(bytes.storage) == [0x7A, 0x02, 0x18, 0x01])
    }

    @Test("Span with flags field 16 (fixed32)")
    func flags() {
        var s = OTLP.Span()
        s.flags = 1
        let bytes = EncodeTraces.encodeSpan(s)
        // field 16 fixed32: tag (16<<3)|5 = 133 = varint 0x85,0x01; LE bytes 01,00,00,00
        #expect(Array(bytes.storage) == [0x85, 0x01, 0x01, 0x00, 0x00, 0x00])
    }

    @Test("Span.Kind unspecified (=0) is omitted (proto3 default)")
    func unspecifiedKindOmitted() {
        var s = OTLP.Span()
        s.kind = .unspecified
        s.name = "x"
        let bytes = EncodeTraces.encodeSpan(s)
        #expect(Array(bytes.storage) == [0x2A, 0x01, 0x78])
    }
}
