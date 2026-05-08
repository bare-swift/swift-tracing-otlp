// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Sendable, Foundation-free OpenTelemetry OTLP encoder for traces over HTTP+protobuf.
///
/// Companion to swift-otlp-exporter (metrics signal). The `OTLP` namespace is
/// defined by swift-otlp-exporter; this package extends it with trace-specific
/// types and re-uses the common types `OTLP.Resource`, `OTLP.InstrumentationScope`,
/// `OTLP.KeyValue`, `OTLP.AnyValue`.
///
/// See `OTLP.encodeTraces(_:)` for the entry point.
public enum TracingOTLP: Sendable {}
