// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter
import Bytes

@Suite("ScopeSpans encoding")
struct ScopeSpansTests {
    @Test("empty ScopeSpans encodes to empty")
    func empty() {
        let bytes = EncodeTraces.encodeScopeSpans(OTLP.ScopeSpans())
        #expect(Array(bytes.storage) == [])
    }

    @Test("ScopeSpans with scope.name=\"x\"")
    func withScope() {
        let sm = OTLP.ScopeSpans(
            scope: OTLP.InstrumentationScope(name: "x")
        )
        let bytes = EncodeTraces.encodeScopeSpans(sm)
        #expect(Array(bytes.storage) == [0x0A, 0x03, 0x0A, 0x01, 0x78])
    }
}

@Suite("ResourceSpans encoding")
struct ResourceSpansTests {
    @Test("empty ResourceSpans encodes to empty")
    func empty() {
        let bytes = EncodeTraces.encodeResourceSpans(OTLP.ResourceSpans())
        #expect(Array(bytes.storage) == [])
    }
}

@Suite("OTLP.encodeTraces end-to-end")
struct OTLPEncodeTracesEndToEndTests {
    @Test("empty ExportTraceServiceRequest encodes to empty Bytes")
    func emptyRequest() {
        let req = OTLP.ExportTraceServiceRequest()
        let payload = OTLP.encodeTraces(req)
        #expect(payload.isEmpty)
    }

    @Test("minimal request: one Resource → one Scope → one Span{name=\"x\"}")
    func minimalRequest() {
        var span = OTLP.Span()
        span.name = "x"
        let req = OTLP.ExportTraceServiceRequest(resourceSpans: [
            OTLP.ResourceSpans(
                resource: OTLP.Resource(),
                scopeSpans: [
                    OTLP.ScopeSpans(
                        scope: OTLP.InstrumentationScope(),
                        spans: [span]
                    )
                ]
            )
        ])
        let payload = OTLP.encodeTraces(req)

        let spanInner: [UInt8] = [0x2A, 0x01, 0x78]
        var scopeSpansInner: [UInt8] = [0x12, UInt8(spanInner.count)]
        scopeSpansInner.append(contentsOf: spanInner)
        var resourceSpansInner: [UInt8] = [0x12, UInt8(scopeSpansInner.count)]
        resourceSpansInner.append(contentsOf: scopeSpansInner)
        var expected: [UInt8] = [0x0A, UInt8(resourceSpansInner.count)]
        expected.append(contentsOf: resourceSpansInner)

        #expect(Array(payload.storage) == expected)
    }

    @Test("realistic request with attributes, status, kind")
    func realisticRequest() {
        var span = OTLP.Span()
        span.traceID = Bytes(repeating: 0xAA, count: 16)
        span.spanID = Bytes(repeating: 0xBB, count: 8)
        span.name = "GET /api"
        span.kind = .server
        span.startTimeUnixNano = 1
        span.endTimeUnixNano = 2
        span.attributes = [OTLP.KeyValue(key: "http.method", value: .string("GET"))]
        span.status = OTLP.Status(code: .ok)

        let req = OTLP.ExportTraceServiceRequest(resourceSpans: [
            OTLP.ResourceSpans(
                resource: OTLP.Resource(attributes: [
                    OTLP.KeyValue(key: "service.name", value: .string("api"))
                ]),
                scopeSpans: [
                    OTLP.ScopeSpans(
                        scope: OTLP.InstrumentationScope(name: "myapp"),
                        spans: [span]
                    )
                ]
            )
        ])
        let payload = OTLP.encodeTraces(req)
        let bs = Array(payload.storage)

        #expect(!bs.isEmpty)
        let nameField: [UInt8] = [0x2A, 0x08] + Array("GET /api".utf8)
        #expect(containsSubsequence(bs, nameField))
        #expect(containsSubsequence(bs, [0x30, 0x02]))           // kind=.server
        #expect(containsSubsequence(bs, [0x7A, 0x02, 0x18, 0x01])) // Status(.ok) wrapped at field 15
        let serviceName: [UInt8] = [0x0A, 0x0C] + Array("service.name".utf8)
        #expect(containsSubsequence(bs, serviceName))
        let apiBytes: [UInt8] = [0x0A, 0x03] + Array("api".utf8)
        #expect(containsSubsequence(bs, apiBytes))
    }

    private func containsSubsequence(_ haystack: [UInt8], _ needle: [UInt8]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        for start in 0...(haystack.count - needle.count) {
            if Array(haystack[start..<start+needle.count]) == needle { return true }
        }
        return false
    }
}
