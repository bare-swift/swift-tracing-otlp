// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import OTLPExporter
import Time

/// swift-time integration for OTLP trace types. The wire-format fields
/// (`startTimeUnixNano`, `endTimeUnixNano`, etc.) remain `UInt64` for
/// proto3 compatibility; these helpers translate to/from `Time.Instant`
/// at the boundary.
///
/// `Time.Instant` is signed `Int64` (pre-1970 representable). OTLP's
/// `UInt64` cannot represent negative nanos, so the conversion clamps
/// negative inputs to 0 — pre-1970 spans don't occur in real distributed
/// tracing data and would corrupt downstream collectors if encoded
/// naively as bit patterns.
extension OTLP.Span {
    /// Convenience initializer accepting `Time.Instant` for the start and
    /// end timestamps. Other fields default to the same values as the
    /// canonical `init`.
    public init(
        traceID: Bytes = Bytes(),
        spanID: Bytes = Bytes(),
        traceState: String = "",
        parentSpanID: Bytes = Bytes(),
        name: String = "",
        kind: Kind = .unspecified,
        startTime: Time.Instant,
        endTime: Time.Instant,
        attributes: [OTLP.KeyValue] = [],
        droppedAttributesCount: UInt32 = 0,
        events: [Event] = [],
        droppedEventsCount: UInt32 = 0,
        links: [Link] = [],
        droppedLinksCount: UInt32 = 0,
        status: OTLP.Status = OTLP.Status(),
        flags: UInt32 = 0
    ) {
        self.init(
            traceID: traceID,
            spanID: spanID,
            traceState: traceState,
            parentSpanID: parentSpanID,
            name: name,
            kind: kind,
            startTimeUnixNano: instantToWireNano(startTime),
            endTimeUnixNano: instantToWireNano(endTime),
            attributes: attributes,
            droppedAttributesCount: droppedAttributesCount,
            events: events,
            droppedEventsCount: droppedEventsCount,
            links: links,
            droppedLinksCount: droppedLinksCount,
            status: status,
            flags: flags
        )
    }

    /// Wall-clock instant when the span started.
    public var startTime: Time.Instant {
        Time.Instant(nanosecondsSinceEpoch: Int64(bitPattern: startTimeUnixNano))
    }

    /// Wall-clock instant when the span ended.
    public var endTime: Time.Instant {
        Time.Instant(nanosecondsSinceEpoch: Int64(bitPattern: endTimeUnixNano))
    }
}

extension OTLP.Span.Event {
    /// Convenience initializer accepting `Time.Instant` for the event's
    /// timestamp.
    public init(
        at instant: Time.Instant,
        name: String = "",
        attributes: [OTLP.KeyValue] = [],
        droppedAttributesCount: UInt32 = 0
    ) {
        self.init(
            timeUnixNano: instantToWireNano(instant),
            name: name,
            attributes: attributes,
            droppedAttributesCount: droppedAttributesCount
        )
    }

    /// Wall-clock instant of this event.
    public var time: Time.Instant {
        Time.Instant(nanosecondsSinceEpoch: Int64(bitPattern: timeUnixNano))
    }
}

/// Translate a `Time.Instant` to OTLP's `UInt64` wire field. Negative
/// nanos clamp to 0 — pre-Unix-epoch spans are not representable in the
/// proto3 schema, so emitting them as bit-pattern UInt64 would be
/// silently corrupt.
@inline(__always)
private func instantToWireNano(_ instant: Time.Instant) -> UInt64 {
    instant.nanosecondsSinceEpoch < 0 ? 0 : UInt64(instant.nanosecondsSinceEpoch)
}
