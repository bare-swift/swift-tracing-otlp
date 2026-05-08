// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import OTLPExporter

/// Internal encoders for the OTLP common types (Resource, InstrumentationScope,
/// KeyValue, AnyValue). The public types are re-used from swift-otlp-exporter;
/// these encoders are duplicated from that package's internal Encoder. Byte
/// output is identical for the same input — verified by porting the same byte
/// vectors as test cases.
enum EncodeCommon {
    static func encodeAnyValue(_ v: OTLP.AnyValue) -> Bytes {
        var w = ProtoWriter()
        switch v {
        case .string(let s):
            w.writeTag(field: 1, wireType: .len)
            w.writeLengthDelimited(Bytes(s.utf8))
        case .bool(let b):
            w.writeTag(field: 2, wireType: .varint)
            w.writeVarint(b ? 1 : 0)
        case .int(let i):
            w.writeTag(field: 3, wireType: .varint)
            w.writeVarint(UInt64(bitPattern: i))
        case .double(let d):
            w.writeTag(field: 4, wireType: .i64)
            w.writeI64(d.bitPattern)
        case .array(let xs):
            var inner = ProtoWriter()
            for x in xs {
                let xb = encodeAnyValue(x)
                inner.writeMessage(xb, fieldNumber: 1)
            }
            w.writeMessage(inner.finish(), fieldNumber: 5)
        case .kvlist(let kvs):
            var inner = ProtoWriter()
            for kv in kvs {
                let kvb = encodeKeyValue(kv)
                inner.writeMessage(kvb, fieldNumber: 1)
            }
            w.writeMessage(inner.finish(), fieldNumber: 6)
        case .bytes(let b):
            w.writeTag(field: 7, wireType: .len)
            w.writeLengthDelimited(b)
        }
        return w.finish()
    }

    static func encodeKeyValue(_ kv: OTLP.KeyValue) -> Bytes {
        var w = ProtoWriter()
        w.writeString(kv.key, fieldNumber: 1)
        let valueBytes = encodeAnyValue(kv.value)
        w.writeMessage(valueBytes, fieldNumber: 2)
        return w.finish()
    }

    static func encodeResource(_ r: OTLP.Resource) -> Bytes {
        var w = ProtoWriter()
        for kv in r.attributes {
            let kvb = encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 1)
        }
        w.writeUInt32(r.droppedAttributesCount, fieldNumber: 2)
        return w.finish()
    }

    static func encodeInstrumentationScope(_ s: OTLP.InstrumentationScope) -> Bytes {
        var w = ProtoWriter()
        w.writeString(s.name, fieldNumber: 1)
        w.writeString(s.version, fieldNumber: 2)
        for kv in s.attributes {
            let kvb = encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 3)
        }
        w.writeUInt32(s.droppedAttributesCount, fieldNumber: 4)
        return w.finish()
    }
}
