# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-05-13

### Added
- `OTLP.TraceContext` value type — W3C Trace Context propagation primitive with `traceID` / `spanID` / `traceFlags` / `traceState` fields.
- `OTLP.TraceContext.traceparent: String?` — computed property serializing the W3C `traceparent` header (`00-<32-hex-traceID>-<16-hex-spanID>-<2-hex-flags>`). Returns `nil` when trace/span ID lengths are wrong.
- `OTLP.TraceContext.parse(traceparent:) -> TraceContext?` — strict parser per W3C spec (rejects wrong length, missing dashes, non-`00` version, uppercase hex, all-zero trace/span IDs).
- `OTLP.TraceContext.isSampled: Bool` — bit 0 of `traceFlags`.
- 13 new tests covering canonical W3C example serialization + parse, round-trip, length/dash/version/case/zero-ID rejections, flag-bit semantics.

### Dependencies
- New: `swift-hex` 0.1.0 — for lowercase-hex byte ↔ string conversion.

### Migration
- Additive only. All v0.2 types, initializers, and helpers unchanged. Existing `OTLP.Span.traceID` / `OTLP.Span.spanID` byte fields are unchanged on the wire; `TraceContext` is a separate propagation type for HTTP-header-level interop, not a replacement.

### Phase 14
- Tranche 14B of [RFC-0019](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0019-phase-14-anchor-otlp-cross-signal.md). 14C will surface a convenience initializer on `OTLP.LogRecord` taking a `TraceContext` to fill the cross-signal correlation fields.

## [0.2.0] - 2026-05-10

### Added
- `OTLP.Span.init(...startTime: Time.Instant, endTime: Time.Instant, ...)` — convenience initializer accepting `Time.Instant` for the start/end timestamps. Internally translates to `UInt64` wire fields.
- `OTLP.Span.startTime` / `OTLP.Span.endTime` computed properties returning `Time.Instant`.
- `OTLP.Span.Event.init(at instant: Time.Instant, ...)` and `OTLP.Span.Event.time` computed property.
- 5 new tests covering wire-field translation, getter round-trip, and negative-instant clamping (pre-1970 spans clamp to 0; `UInt64` cannot represent them).

### Dependencies
- New: `swift-time` 0.1.0 — for the `Time.Instant` type used by the helpers.

### Migration
- Additive only. The existing `startTimeUnixNano: UInt64` field and the canonical `init(...)` continue to work unchanged. Negative `Time.Instant` values clamp to `0` on the wire (pre-1970 spans don't occur in real distributed-tracing data).

## [0.1.0] - 2026-05-08

### Added
- `OTLP.encodeTraces(_:)` — Sendable, Foundation-free, non-throwing encoder of `OTLP.ExportTraceServiceRequest` to protobuf wire bytes ready for `HTTP POST /v1/traces`.
- Full OTLP traces.v1 schema: `OTLP.Span` (16 fields), `OTLP.Span.Event`, `OTLP.Span.Link`, `OTLP.Span.Kind` (6 cases), `OTLP.Status` + `OTLP.Status.Code` (3 cases).
- Top-level: `OTLP.ResourceSpans`, `OTLP.ScopeSpans`, `OTLP.ExportTraceServiceRequest`.
- Re-uses `OTLP.Resource`, `OTLP.InstrumentationScope`, `OTLP.KeyValue`, `OTLP.AnyValue` from swift-otlp-exporter (extends the same `OTLP` namespace).
- `TracingOTLPError` typed-error enum (no cases in v0.1; reserved for future signal types).
- DocC documentation, full README example, NOTICE crediting OpenTelemetry's opentelemetry-proto + the swift-bytes/varint/otlp-exporter dependency chain.

### Dependencies
- `swift-bytes` 0.1.0.
- `swift-varint` 0.1.0.
- `swift-otlp-exporter` 0.1.0 — **first time the bare-swift ecosystem ships a package depending on three intra-ecosystem packages.**

### Limitations (out of scope for v0.1)
- gRPC OTLP transport.
- JSON OTLP variant.
- HTTP transport — caller wires URLSession / async-http-client / NIO.
- Decoder.
- Sampling.
- Trace-ID / Span-ID generation helpers (caller provides).
- Trace-ID / Span-ID length enforcement (proto requires 16/8 bytes; collector rejects invalid).
- Apple swift-distributed-tracing adapter — that's Tranche 3B's separate package.
