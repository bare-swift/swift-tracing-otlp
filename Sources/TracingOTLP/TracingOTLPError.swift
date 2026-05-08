// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Errors thrown by `OTLP.encodeTraces(_:)` and related encoders.
///
/// **v0.1: this enum has no cases.** Encoding pure value-type data has no
/// runtime failure modes; Swift's UTF-8 invariant guarantees valid string
/// bytes. The type exists as a forward-compatible extension point. Mirrors
/// `OTLPError` in swift-otlp-exporter.
public enum TracingOTLPError: Error, Equatable, Sendable {}
