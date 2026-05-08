// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import OTLPExporter

extension OTLP {
    /// `opentelemetry.proto.trace.v1.Status`.
    public struct Status: Sendable, Equatable {
        public enum Code: UInt32, Sendable, Equatable {
            case unset = 0
            case ok = 1
            case error = 2
        }

        public var message: String
        public var code: Code

        public init(message: String = "", code: Code = .unset) {
            self.message = message
            self.code = code
        }
    }
}
