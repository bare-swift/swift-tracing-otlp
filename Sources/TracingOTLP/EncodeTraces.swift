// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import OTLPExporter

/// Internal per-message encoders for OTLP traces.v1. Each function produces
/// the inner protobuf payload for one OTLP message; callers wrap with tag+length
/// when embedding (via `ProtoWriter.writeMessage`).
enum EncodeTraces {
    // MARK: - Status
    static func encodeStatus(_ s: OTLP.Status) -> Bytes {
        var w = ProtoWriter()
        // field 2 message (string)
        w.writeString(s.message, fieldNumber: 2)
        // field 3 code (enum)
        w.writeEnum(s.code.rawValue, fieldNumber: 3)
        return w.finish()
    }

    // MARK: - Span (16 fields)
    static func encodeSpan(_ s: OTLP.Span) -> Bytes {
        var w = ProtoWriter()
        // field 1 trace_id (bytes)
        w.writeBytes(s.traceID, fieldNumber: 1)
        // field 2 span_id (bytes)
        w.writeBytes(s.spanID, fieldNumber: 2)
        // field 3 trace_state (string)
        w.writeString(s.traceState, fieldNumber: 3)
        // field 4 parent_span_id (bytes)
        w.writeBytes(s.parentSpanID, fieldNumber: 4)
        // field 5 name (string)
        w.writeString(s.name, fieldNumber: 5)
        // field 6 kind (enum)
        w.writeEnum(s.kind.rawValue, fieldNumber: 6)
        // field 7 start_time_unix_nano (fixed64)
        w.writeFixed64(s.startTimeUnixNano, fieldNumber: 7)
        // field 8 end_time_unix_nano (fixed64)
        w.writeFixed64(s.endTimeUnixNano, fieldNumber: 8)
        // field 9 attributes (repeated KeyValue)
        for kv in s.attributes {
            let kvb = EncodeCommon.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 9)
        }
        // field 10 dropped_attributes_count (uint32)
        w.writeUInt32(s.droppedAttributesCount, fieldNumber: 10)
        // field 11 events (repeated Event)
        for e in s.events {
            let eb = encodeSpanEvent(e)
            w.writeMessage(eb, fieldNumber: 11)
        }
        // field 12 dropped_events_count (uint32)
        w.writeUInt32(s.droppedEventsCount, fieldNumber: 12)
        // field 13 links (repeated Link)
        for l in s.links {
            let lb = encodeSpanLink(l)
            w.writeMessage(lb, fieldNumber: 13)
        }
        // field 14 dropped_links_count (uint32)
        w.writeUInt32(s.droppedLinksCount, fieldNumber: 14)
        // field 15 status (message)
        let statusBytes = encodeStatus(s.status)
        if !statusBytes.isEmpty {
            w.writeMessage(statusBytes, fieldNumber: 15)
        }
        // field 16 flags (fixed32)
        w.writeFixed32(s.flags, fieldNumber: 16)
        return w.finish()
    }

    // MARK: - Span.Event
    static func encodeSpanEvent(_ e: OTLP.Span.Event) -> Bytes {
        var w = ProtoWriter()
        // field 1 time_unix_nano (fixed64)
        w.writeFixed64(e.timeUnixNano, fieldNumber: 1)
        // field 2 name (string)
        w.writeString(e.name, fieldNumber: 2)
        // field 3 attributes (repeated KeyValue)
        for kv in e.attributes {
            let kvb = EncodeCommon.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 3)
        }
        // field 4 dropped_attributes_count (uint32)
        w.writeUInt32(e.droppedAttributesCount, fieldNumber: 4)
        return w.finish()
    }

    // MARK: - Span.Link
    static func encodeSpanLink(_ l: OTLP.Span.Link) -> Bytes {
        var w = ProtoWriter()
        // field 1 trace_id (bytes)
        w.writeBytes(l.traceID, fieldNumber: 1)
        // field 2 span_id (bytes)
        w.writeBytes(l.spanID, fieldNumber: 2)
        // field 3 trace_state (string)
        w.writeString(l.traceState, fieldNumber: 3)
        // field 4 attributes (repeated KeyValue)
        for kv in l.attributes {
            let kvb = EncodeCommon.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 4)
        }
        // field 5 dropped_attributes_count (uint32)
        w.writeUInt32(l.droppedAttributesCount, fieldNumber: 5)
        // field 6 flags (fixed32)
        w.writeFixed32(l.flags, fieldNumber: 6)
        return w.finish()
    }

    // MARK: - ScopeSpans
    static func encodeScopeSpans(_ ss: OTLP.ScopeSpans) -> Bytes {
        var w = ProtoWriter()
        // field 1 scope (message); omit if empty
        let scopeBytes = EncodeCommon.encodeInstrumentationScope(ss.scope)
        if !scopeBytes.isEmpty {
            w.writeMessage(scopeBytes, fieldNumber: 1)
        }
        // field 2 spans (repeated)
        for span in ss.spans {
            let sb = encodeSpan(span)
            w.writeMessage(sb, fieldNumber: 2)
        }
        // field 3 schema_url
        w.writeString(ss.schemaURL, fieldNumber: 3)
        return w.finish()
    }

    // MARK: - ResourceSpans
    static func encodeResourceSpans(_ rs: OTLP.ResourceSpans) -> Bytes {
        var w = ProtoWriter()
        // field 1 resource (message); omit if empty
        let resourceBytes = EncodeCommon.encodeResource(rs.resource)
        if !resourceBytes.isEmpty {
            w.writeMessage(resourceBytes, fieldNumber: 1)
        }
        // field 2 scope_spans (repeated)
        for ss in rs.scopeSpans {
            let ssb = encodeScopeSpans(ss)
            w.writeMessage(ssb, fieldNumber: 2)
        }
        // field 3 schema_url
        w.writeString(rs.schemaURL, fieldNumber: 3)
        return w.finish()
    }

    // MARK: - ExportTraceServiceRequest
    static func encodeExportTraceServiceRequest(
        _ req: OTLP.ExportTraceServiceRequest
    ) -> Bytes {
        var w = ProtoWriter()
        // field 1 resource_spans (repeated)
        for rs in req.resourceSpans {
            let rsb = encodeResourceSpans(rs)
            w.writeMessage(rsb, fieldNumber: 1)
        }
        return w.finish()
    }
}

// MARK: - Public entry point

extension OTLP {
    /// Encode an `ExportTraceServiceRequest` to its protobuf wire form.
    /// The returned `Bytes` is the body for `HTTP POST /v1/traces` with
    /// `Content-Type: application/x-protobuf`.
    public static func encodeTraces(_ request: ExportTraceServiceRequest) -> Bytes {
        EncodeTraces.encodeExportTraceServiceRequest(request)
    }
}
