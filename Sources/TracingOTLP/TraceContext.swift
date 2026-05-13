// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Hex
import OTLPExporter

extension OTLP {
    /// W3C Trace Context propagation value.
    ///
    /// Carries the four pieces of state defined by the W3C `traceparent` and
    /// `tracestate` headers: 16-byte trace ID, 8-byte span ID, 8-bit flags
    /// byte, and an opaque `tracestate` string. Use ``traceparent`` to
    /// serialize a propagation header and ``parse(traceparent:)`` to ingest
    /// one from an inbound request.
    ///
    /// The "sampled" flag (bit 0 of `traceFlags`) is the only flag defined by
    /// the spec at present. Convenience accessor: ``isSampled``.
    public struct TraceContext: Sendable, Equatable {
        /// 16-byte trace identifier. Per W3C, the all-zero ID is invalid.
        public var traceID: Bytes
        /// 8-byte span identifier. Per W3C, the all-zero ID is invalid.
        public var spanID: Bytes
        /// 8-bit flags byte. Bit 0 is the "sampled" flag.
        public var traceFlags: UInt8
        /// Opaque vendor-specific propagation state (W3C `tracestate` header).
        public var traceState: String

        public init(
            traceID: Bytes = Bytes(),
            spanID: Bytes = Bytes(),
            traceFlags: UInt8 = 0,
            traceState: String = ""
        ) {
            self.traceID = traceID
            self.spanID = spanID
            self.traceFlags = traceFlags
            self.traceState = traceState
        }

        /// `true` iff bit 0 of ``traceFlags`` is set.
        public var isSampled: Bool {
            (traceFlags & 0x01) != 0
        }

        /// W3C `traceparent` header value for this context.
        ///
        /// Format: `00-<32-hex-traceID>-<16-hex-spanID>-<2-hex-flags>` (version
        /// `00`, lowercase hex). Returns `nil` when ``traceID`` or ``spanID``
        /// are not the required 16 / 8 bytes — the spec does not define a
        /// representation for malformed IDs.
        public var traceparent: String? {
            guard traceID.count == 16, spanID.count == 8 else { return nil }
            let tid = Hex.encode(traceID.storage)
            let sid = Hex.encode(spanID.storage)
            let flagHi = Self.hexDigit(Int(traceFlags >> 4))
            let flagLo = Self.hexDigit(Int(traceFlags & 0x0f))
            return "00-\(tid)-\(sid)-\(flagHi)\(flagLo)"
        }

        /// Parse a W3C `traceparent` header into a `TraceContext`.
        ///
        /// Accepts only version `00` per the W3C spec's strict-parsing rule
        /// (other versions are reserved and a strict parser must reject
        /// them). Rejects: wrong field lengths, non-hex characters, all-zero
        /// trace or span ID, the reserved version `ff`, and uppercase hex.
        ///
        /// ``traceState`` is left empty — set it separately from the
        /// `tracestate` header value if present.
        public static func parse(traceparent: String) -> TraceContext? {
            // 2 + 1 + 32 + 1 + 16 + 1 + 2 = 55
            guard traceparent.utf8.count == 55 else { return nil }
            let bytes = Array(traceparent.utf8)
            guard bytes[2] == 0x2d, bytes[35] == 0x2d, bytes[52] == 0x2d else {
                return nil
            }
            // Version 00 only.
            guard bytes[0] == 0x30, bytes[1] == 0x30 else { return nil }
            guard let tid = decodeLowercaseHex(bytes, 3, 32),
                  let sid = decodeLowercaseHex(bytes, 36, 16),
                  let flags = decodeLowercaseHex(bytes, 53, 2)
            else { return nil }
            // Trace ID and span ID must not be all zeros.
            if tid.allSatisfy({ $0 == 0 }) { return nil }
            if sid.allSatisfy({ $0 == 0 }) { return nil }
            return TraceContext(
                traceID: Bytes(tid),
                spanID: Bytes(sid),
                traceFlags: flags[0],
                traceState: ""
            )
        }

        // MARK: - Internal hex helpers
        //
        // We don't use `Hex.decode` because the W3C spec requires *lowercase*
        // hex for the traceparent header; `Hex.decode` accepts both cases.

        private static func decodeLowercaseHex(
            _ bytes: [UInt8], _ start: Int, _ length: Int
        ) -> [UInt8]? {
            var out = [UInt8]()
            out.reserveCapacity(length / 2)
            var i = start
            let end = start + length
            while i < end {
                guard let hi = lowercaseHexNibble(bytes[i]),
                      let lo = lowercaseHexNibble(bytes[i + 1])
                else { return nil }
                out.append((hi << 4) | lo)
                i += 2
            }
            return out
        }

        private static func lowercaseHexNibble(_ b: UInt8) -> UInt8? {
            switch b {
            case 0x30...0x39: return b - 0x30          // '0'-'9'
            case 0x61...0x66: return b - 0x61 + 10     // 'a'-'f'
            default: return nil
            }
        }

        private static func hexDigit(_ n: Int) -> Character {
            switch n {
            case 0...9: return Character(Unicode.Scalar(0x30 + n)!)
            default: return Character(Unicode.Scalar(0x61 + n - 10)!)
            }
        }
    }
}
