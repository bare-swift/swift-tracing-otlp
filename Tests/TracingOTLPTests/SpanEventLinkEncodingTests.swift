// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter
import Bytes

@Suite("Span.Event encoding")
struct SpanEventEncodingTests {
    @Test("empty Event encodes to empty")
    func empty() {
        let bytes = EncodeTraces.encodeSpanEvent(OTLP.Span.Event())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Event with name=\"e\" and timeUnixNano=1")
    func nameAndTime() {
        var e = OTLP.Span.Event()
        e.timeUnixNano = 1
        e.name = "e"
        let bytes = EncodeTraces.encodeSpanEvent(e)
        var expected: [UInt8] = [0x09, 0x01, 0, 0, 0, 0, 0, 0, 0]
        expected.append(contentsOf: [0x12, 0x01, 0x65])
        #expect(Array(bytes.storage) == expected)
    }

    @Test("Event with attributes (field 3)")
    func attributes() {
        var e = OTLP.Span.Event()
        e.attributes = [OTLP.KeyValue(key: "k", value: .string("v"))]
        let bytes = EncodeTraces.encodeSpanEvent(e)
        var expected: [UInt8] = [0x1A, 0x08]
        expected.append(contentsOf: [0x0A, 0x01, 0x6B, 0x12, 0x03, 0x0A, 0x01, 0x76])
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("Span.Link encoding")
struct SpanLinkEncodingTests {
    @Test("empty Link encodes to empty")
    func empty() {
        let bytes = EncodeTraces.encodeSpanLink(OTLP.Span.Link())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Link with traceID + spanID")
    func ids() {
        var l = OTLP.Span.Link()
        l.traceID = Bytes(repeating: 0xEE, count: 16)
        l.spanID = Bytes(repeating: 0xFF, count: 8)
        let bytes = EncodeTraces.encodeSpanLink(l)
        var expected: [UInt8] = [0x0A, 0x10]
        expected.append(contentsOf: Array(repeating: 0xEE, count: 16))
        expected.append(contentsOf: [0x12, 0x08])
        expected.append(contentsOf: Array(repeating: 0xFF, count: 8))
        #expect(Array(bytes.storage) == expected)
    }

    @Test("Link with flags (field 6, fixed32)")
    func flags() {
        var l = OTLP.Span.Link()
        l.flags = 1
        let bytes = EncodeTraces.encodeSpanLink(l)
        // field 6 fixed32: tag (6<<3)|5 = 53 = 0x35; LE bytes 01,00,00,00
        #expect(Array(bytes.storage) == [0x35, 0x01, 0x00, 0x00, 0x00])
    }
}

@Suite("Span with Event + Link integration")
struct SpanEventLinkIntegrationTests {
    @Test("Span with one event and one link")
    func spanWithEventAndLink() {
        var span = OTLP.Span()
        var event = OTLP.Span.Event()
        event.name = "e"
        span.events = [event]
        var link = OTLP.Span.Link()
        link.traceID = Bytes(repeating: 0xEE, count: 16)
        link.spanID = Bytes(repeating: 0xFF, count: 8)
        span.links = [link]
        let bytes = EncodeTraces.encodeSpan(span)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x5A, 0x03, 0x12, 0x01, 0x65])
        expected.append(contentsOf: [0x6A, 0x1C, 0x0A, 0x10])
        expected.append(contentsOf: Array(repeating: 0xEE, count: 16))
        expected.append(contentsOf: [0x12, 0x08])
        expected.append(contentsOf: Array(repeating: 0xFF, count: 8))
        #expect(Array(bytes.storage) == expected)
    }
}
