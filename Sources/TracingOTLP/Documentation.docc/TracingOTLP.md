# ``TracingOTLP``

Sendable, Foundation-free OpenTelemetry OTLP encoder for traces over HTTP+protobuf.

## Overview

`swift-tracing-otlp` produces ready-to-send HTTP request bodies in the
OTLP/protobuf wire format for the **traces** signal. Pure encoder — no
HTTP transport, no sampling. Caller wires their HTTP client of choice
and sends the returned `Bytes` to `POST /v1/traces` with
`Content-Type: application/x-protobuf`.

Companion to [swift-otlp-exporter](https://github.com/bare-swift/swift-otlp-exporter) (metrics signal). The `OTLP` namespace is defined by swift-otlp-exporter; this package extends it with trace-specific types and re-uses the common types (`OTLP.Resource`, `OTLP.InstrumentationScope`, `OTLP.KeyValue`, `OTLP.AnyValue`).

```swift
import OTLPExporter
import TracingOTLP

let request = OTLP.ExportTraceServiceRequest(resourceSpans: [
    // ... build OTLP-shaped trace data ...
])
let payload = OTLP.encodeTraces(request)  // Bytes ready for HTTP POST
```

The public Swift types mirror the OTLP proto schema 1:1.

## Topics

### Top-level

- ``TracingOTLP``

### W3C Trace Context

`OTLP.TraceContext` carries `traceID` / `spanID` / `traceFlags` / `traceState` and round-trips the W3C `traceparent` header. See the README for usage.

### Errors

- ``TracingOTLPError``
