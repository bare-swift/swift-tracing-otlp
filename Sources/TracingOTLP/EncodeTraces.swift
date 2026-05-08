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
}
