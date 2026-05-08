# Test-parity exceptions

Per [RFC-0002](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0002-test-parity-policy.md) and its 2026-05-07 amendment per [RFC-0004](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0004-inline-test-vectors.md), this file documents how `swift-tracing-otlp` validates correctness.

## Source: opentelemetry-proto + protobuf wire-format spec

There is no upstream Rust crate to track parity against. Two layers of correctness:

1. **Wire-format primitives** (`ProtoWriter`) — the protobuf wire format spec is the source of truth. Test vectors port directly from swift-otlp-exporter, where they were derived from the spec
   (https://protobuf.dev/programming-guides/encoding/) and verifiable by hand.

2. **OTLP traces encoding** — the OTLP proto schema
   (https://github.com/open-telemetry/opentelemetry-proto/blob/main/opentelemetry/proto/trace/v1/trace.proto)
   is the source of truth for field numbers, wire types, oneof shapes,
   and proto3 optional/default semantics. Test vectors compose
   mechanically from the wire-format primitives applied per the schema.

Test layout:

- `ProtoWriterTests.swift` — wire-format primitives (varint, I32, I64, length-delimited, packed-repeated, ZigZag).
- `EncodeCommonTests.swift` — KeyValue / AnyValue / Resource / InstrumentationScope encoders (re-implementations using the public types from swift-otlp-exporter).
- `StatusEncodingTests.swift` — Status message + StatusCode enum.
- `SpanKindTests.swift` — SpanKind enum raw values.
- `SpanEncodingTests.swift` — full Span message (16 fields).
- `SpanEventLinkEncodingTests.swift` — Span.Event and Span.Link sub-messages.
- `EndToEndTests.swift` — full ExportTraceServiceRequest with multi-resource, multi-scope, multi-span content.

## Out of scope for v0.1

- gRPC OTLP transport.
- JSON OTLP variant.
- HTTP transport.
- Decoder.
- Sampling.
- Trace-ID / Span-ID length enforcement (proto requires 16/8 bytes; collector rejects invalid lengths).
- Adapter to Apple's swift-distributed-tracing (Tranche 3B's separate package).
- Logs (OTLP logs.v1) — Tranche 3C if budget allows.

## Refresh

When the OTLP traces.v1 proto schema changes (rare), re-read and update tests for any affected message.

- opentelemetry-proto: tracked at upstream commit (record at next refresh).
- protobuf wire format spec: stable since 2008; no pin needed.
