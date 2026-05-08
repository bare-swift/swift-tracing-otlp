// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Varint

/// Internal protobuf wire-format writer. Bytes-backed; produces exact
/// proto3 wire format. Duplicated from swift-otlp-exporter; the wire format
/// is stable, the duplication is the cleanest path per RFC-0007's anchor RFC.
struct ProtoWriter {
    enum WireType: UInt32 {
        case varint = 0
        case i64    = 1
        case len    = 2
        case i32    = 5
    }

    private var bytes: Bytes

    init(reservingCapacity capacity: Int = 256) {
        self.bytes = Bytes(reservingCapacity: capacity)
    }

    consuming func finish() -> Bytes { bytes }

    mutating func writeTag(field: UInt32, wireType: WireType) {
        let tag: UInt64 = (UInt64(field) << 3) | UInt64(wireType.rawValue)
        writeVarint(tag)
    }

    mutating func writeVarint(_ value: UInt64) {
        bytes.append(contentsOf: Varint.encode(value))
    }

    mutating func writeI32(_ value: UInt32) {
        bytes.append(UInt8(truncatingIfNeeded: value))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    }

    mutating func writeI64(_ value: UInt64) {
        bytes.append(UInt8(truncatingIfNeeded: value))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
        bytes.append(UInt8(truncatingIfNeeded: value >> 32))
        bytes.append(UInt8(truncatingIfNeeded: value >> 40))
        bytes.append(UInt8(truncatingIfNeeded: value >> 48))
        bytes.append(UInt8(truncatingIfNeeded: value >> 56))
    }

    mutating func writeLengthDelimited(_ payload: Bytes) {
        writeVarint(UInt64(payload.count))
        bytes.append(contentsOf: payload.storage)
    }

    // MARK: - Field helpers (proto3 default omission)

    mutating func writeUInt64(_ value: UInt64, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(value)
    }

    mutating func writeUInt32(_ value: UInt32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(UInt64(value))
    }

    mutating func writeBool(_ value: Bool, fieldNumber: UInt32) {
        guard value else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(1)
    }

    mutating func writeString(_ value: String, fieldNumber: UInt32) {
        guard !value.isEmpty else { return }
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(Bytes(value.utf8))
    }

    mutating func writeBytes(_ value: Bytes, fieldNumber: UInt32) {
        guard !value.isEmpty else { return }
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(value)
    }

    mutating func writeMessage(_ payload: Bytes, fieldNumber: UInt32) {
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(payload)
    }

    mutating func writeFixed64(_ value: UInt64, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .i64)
        writeI64(value)
    }

    mutating func writeFixed32(_ value: UInt32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .i32)
        writeI32(value)
    }

    mutating func writeEnum(_ value: UInt32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(UInt64(value))
    }
}
