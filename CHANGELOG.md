# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
