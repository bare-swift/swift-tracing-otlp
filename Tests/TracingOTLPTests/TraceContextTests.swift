// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import OTLPExporter
import Testing
@testable import TracingOTLP

@Suite("OTLP.TraceContext")
struct TraceContextTests {
    private static let canonicalTraceparent =
        "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
    private static let canonicalTraceID = Bytes([
        0x4b, 0xf9, 0x2f, 0x35, 0x77, 0xb3, 0x4d, 0xa6,
        0xa3, 0xce, 0x92, 0x9d, 0x0e, 0x0e, 0x47, 0x36
    ])
    private static let canonicalSpanID = Bytes([
        0x00, 0xf0, 0x67, 0xaa, 0x0b, 0xa9, 0x02, 0xb7
    ])

    @Test("serializes the W3C example traceparent verbatim")
    func serializeCanonical() {
        let ctx = OTLP.TraceContext(
            traceID: Self.canonicalTraceID,
            spanID: Self.canonicalSpanID,
            traceFlags: 0x01
        )
        #expect(ctx.traceparent == Self.canonicalTraceparent)
    }

    @Test("parses the W3C example traceparent")
    func parseCanonical() {
        let ctx = OTLP.TraceContext.parse(traceparent: Self.canonicalTraceparent)
        #expect(ctx?.traceID == Self.canonicalTraceID)
        #expect(ctx?.spanID == Self.canonicalSpanID)
        #expect(ctx?.traceFlags == 0x01)
        #expect(ctx?.isSampled == true)
    }

    @Test("round-trips serialize → parse")
    func roundTripSerializeParse() {
        let original = OTLP.TraceContext(
            traceID: Self.canonicalTraceID,
            spanID: Self.canonicalSpanID,
            traceFlags: 0x00
        )
        let header = original.traceparent
        let parsed = OTLP.TraceContext.parse(traceparent: header ?? "")
        #expect(parsed?.traceID == original.traceID)
        #expect(parsed?.spanID == original.spanID)
        #expect(parsed?.traceFlags == 0x00)
        #expect(parsed?.isSampled == false)
    }

    @Test("traceparent is nil when traceID is wrong length")
    func traceparentNilOnBadTraceID() {
        let ctx = OTLP.TraceContext(
            traceID: Bytes([0x01, 0x02]),
            spanID: Self.canonicalSpanID,
            traceFlags: 0x01
        )
        #expect(ctx.traceparent == nil)
    }

    @Test("traceparent is nil when spanID is wrong length")
    func traceparentNilOnBadSpanID() {
        let ctx = OTLP.TraceContext(
            traceID: Self.canonicalTraceID,
            spanID: Bytes([0x01]),
            traceFlags: 0x01
        )
        #expect(ctx.traceparent == nil)
    }

    @Test("parse rejects wrong total length")
    func parseRejectsWrongLength() {
        #expect(OTLP.TraceContext.parse(traceparent: "00-abc-def-01") == nil)
        #expect(OTLP.TraceContext.parse(traceparent: Self.canonicalTraceparent + "0") == nil)
    }

    @Test("parse rejects missing dashes")
    func parseRejectsMissingDashes() {
        // Replace dash at index 2 with 'x'.
        var s = Self.canonicalTraceparent
        let dashIdx = s.index(s.startIndex, offsetBy: 2)
        s.replaceSubrange(dashIdx...dashIdx, with: "x")
        #expect(OTLP.TraceContext.parse(traceparent: s) == nil)
    }

    @Test("parse rejects version other than 00")
    func parseRejectsNonZeroVersion() {
        let s = "01-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
        #expect(OTLP.TraceContext.parse(traceparent: s) == nil)
        let reserved = "ff-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
        #expect(OTLP.TraceContext.parse(traceparent: reserved) == nil)
    }

    @Test("parse rejects uppercase hex (W3C requires lowercase)")
    func parseRejectsUppercase() {
        let upper = "00-4BF92F3577B34DA6A3CE929D0E0E4736-00f067aa0ba902b7-01"
        #expect(OTLP.TraceContext.parse(traceparent: upper) == nil)
    }

    @Test("parse rejects all-zero trace ID")
    func parseRejectsZeroTraceID() {
        let s = "00-00000000000000000000000000000000-00f067aa0ba902b7-01"
        #expect(OTLP.TraceContext.parse(traceparent: s) == nil)
    }

    @Test("parse rejects all-zero span ID")
    func parseRejectsZeroSpanID() {
        let s = "00-4bf92f3577b34da6a3ce929d0e0e4736-0000000000000000-01"
        #expect(OTLP.TraceContext.parse(traceparent: s) == nil)
    }

    @Test("isSampled reflects bit 0 only")
    func isSampledReflectsBit0() {
        var ctx = OTLP.TraceContext(
            traceID: Self.canonicalTraceID,
            spanID: Self.canonicalSpanID,
            traceFlags: 0x00
        )
        #expect(ctx.isSampled == false)
        ctx.traceFlags = 0x01
        #expect(ctx.isSampled == true)
        ctx.traceFlags = 0xfe  // every bit except bit 0
        #expect(ctx.isSampled == false)
        ctx.traceFlags = 0xff
        #expect(ctx.isSampled == true)
    }

    @Test("traceparent encodes flags as two lowercase hex digits")
    func traceparentEncodesFlags() {
        let ctx = OTLP.TraceContext(
            traceID: Self.canonicalTraceID,
            spanID: Self.canonicalSpanID,
            traceFlags: 0xab
        )
        #expect(ctx.traceparent?.hasSuffix("-ab") == true)
    }

    @Test("traceState is initialized empty and preserved on parse")
    func traceStateDefaultEmpty() {
        let parsed = OTLP.TraceContext.parse(traceparent: Self.canonicalTraceparent)
        #expect(parsed?.traceState == "")
    }
}
