// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter
import Time

@Suite("Time integration on OTLP.Span")
struct SpanTimeIntegrationTests {
    @Test("init(startTime:endTime:) translates to UInt64 wire fields")
    func initWithInstants() {
        let start = Time.Instant(nanosecondsSinceEpoch: 1_700_000_000_000_000_000)
        let end   = Time.Instant(nanosecondsSinceEpoch: 1_700_000_001_000_000_000)
        let span = OTLP.Span(name: "op", startTime: start, endTime: end)
        #expect(span.startTimeUnixNano == 1_700_000_000_000_000_000)
        #expect(span.endTimeUnixNano   == 1_700_000_001_000_000_000)
        #expect(span.name == "op")
    }

    @Test(".startTime / .endTime getters round-trip the wire field")
    func instantRoundTrip() {
        let span = OTLP.Span(
            name: "op",
            startTimeUnixNano: 1_700_000_000_500_000_000,
            endTimeUnixNano:   1_700_000_001_500_000_000
        )
        #expect(span.startTime.nanosecondsSinceEpoch == 1_700_000_000_500_000_000)
        #expect(span.endTime.nanosecondsSinceEpoch   == 1_700_000_001_500_000_000)
    }

    @Test("negative Instants clamp to 0 on wire (pre-1970 spans)")
    func negativeClamps() {
        let span = OTLP.Span(
            name: "op",
            startTime: Time.Instant(nanosecondsSinceEpoch: -1_000_000_000),
            endTime:   Time.Instant(nanosecondsSinceEpoch: 1_000_000_000)
        )
        #expect(span.startTimeUnixNano == 0)
        #expect(span.endTimeUnixNano == 1_000_000_000)
    }
}

@Suite("Time integration on OTLP.Span.Event")
struct EventTimeIntegrationTests {
    @Test("init(at:name:) sets timeUnixNano")
    func initWithInstant() {
        let i = Time.Instant(nanosecondsSinceEpoch: 1_700_000_000_000_000_000)
        let e = OTLP.Span.Event(at: i, name: "checkpoint")
        #expect(e.timeUnixNano == 1_700_000_000_000_000_000)
        #expect(e.name == "checkpoint")
    }

    @Test(".time getter round-trips")
    func timeGetter() {
        let e = OTLP.Span.Event(timeUnixNano: 42_000_000_000, name: "x")
        #expect(e.time.nanosecondsSinceEpoch == 42_000_000_000)
    }
}
