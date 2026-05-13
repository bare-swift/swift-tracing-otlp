# swift-tracing-otlp

Sendable, Foundation-free [OpenTelemetry OTLP](https://opentelemetry.io/docs/specs/otlp/) wire-format encoder for **traces** over HTTP+protobuf.

Pure encoder — no transport, no sampling. Output is [`Bytes`](https://github.com/bare-swift/swift-bytes) ready as the body of an `HTTP POST /v1/traces` request to an OTLP collector with `Content-Type: application/x-protobuf`.

Companion to [swift-otlp-exporter](https://github.com/bare-swift/swift-otlp-exporter) (metrics signal). Together they cover the metrics+traces half of OpenTelemetry's signal set.

Part of the [bare-swift](https://github.com/bare-swift) ecosystem. Phase 3 Tranche 3A.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-tracing-otlp.git", from: "0.3.0")
```

```swift
.product(name: "TracingOTLP", package: "swift-tracing-otlp")
```

## Usage

```swift
import OTLPExporter   // re-uses Resource, InstrumentationScope, KeyValue, AnyValue
import TracingOTLP    // adds Span, ResourceSpans, ScopeSpans, ExportTraceServiceRequest
import Bytes

let request = OTLP.ExportTraceServiceRequest(resourceSpans: [
    OTLP.ResourceSpans(
        resource: OTLP.Resource(attributes: [
            OTLP.KeyValue(key: "service.name", value: .string("api"))
        ]),
        scopeSpans: [
            OTLP.ScopeSpans(
                scope: OTLP.InstrumentationScope(name: "myapp", version: "1.0"),
                spans: [
                    {
                        var span = OTLP.Span(
                            traceID: Bytes([
                                0x4b,0xf9,0x2f,0x35,0x77,0xb3,0x4d,0xa6,
                                0xa3,0xce,0x92,0x9d,0x0e,0x0e,0x47,0x36
                            ]),
                            spanID: Bytes([
                                0x00,0xf0,0x67,0xaa,0x0b,0xa9,0x02,0xb7
                            ]),
                            name: "GET /api/users",
                            kind: .server,
                            startTimeUnixNano: 1_700_000_000_000_000_000,
                            endTimeUnixNano:   1_700_000_000_500_000_000
                        )
                        span.attributes = [.init(key: "http.method", value: .string("GET"))]
                        span.status = OTLP.Status(code: .ok)
                        return span
                    }()
                ]
            )
        ]
    )
])

let payload: Bytes = OTLP.encodeTraces(request)
// HTTP POST /v1/traces, Content-Type: application/x-protobuf, body = payload.storage
```

## Code-sharing with swift-otlp-exporter

The `OTLP` namespace is defined by swift-otlp-exporter; this package extends it with trace-specific types. Common types (`OTLP.Resource`, `OTLP.InstrumentationScope`, `OTLP.KeyValue`, `OTLP.AnyValue`) come from swift-otlp-exporter and are re-used directly. The proto-encoding internals (`ProtoWriter`, per-message common encoders) are intentionally duplicated to keep this package independently shippable. Wire format produced is byte-identical for the shared message types.

## W3C Trace Context propagation

Since v0.3, `OTLP.TraceContext` carries the four pieces of W3C `traceparent` / `tracestate` state and serializes/parses the header value:

```swift
let inbound = OTLP.TraceContext.parse(
    traceparent: "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
)!
// inbound.isSampled == true

let outbound = OTLP.TraceContext(
    traceID: inbound.traceID,
    spanID: Bytes([/* new child span ID */]),
    traceFlags: inbound.traceFlags
)
let header: String = outbound.traceparent!  // "00-<...>-<...>-01"
```

The parser is strict per the W3C spec — version `00` only, lowercase hex, all-zero trace/span IDs rejected.

## Scope

**v0.3 covers:** OTLP traces over HTTP+protobuf. Full Span schema (16 fields including events and links), all 6 SpanKind values, Status with all 3 codes. `Time.Instant` convenience integration (v0.2). W3C `TraceContext` propagation (v0.3).

**Out of scope (deferred):** gRPC OTLP, JSON OTLP, HTTP transport itself, decoder, sampling, trace/span ID generation, Apple swift-distributed-tracing adapter (Tranche 3B's separate package).

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-tracing-otlp/>

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
