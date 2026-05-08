// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import Bytes

@Suite("ProtoWriter — wire-format primitives")
struct ProtoWriterTests {

    // MARK: - Varint

    @Test("writeVarint of 0, 1, 127, 128, 16383, 16384, UInt64.max")
    func writeVarintBoundaries() {
        var w = ProtoWriter()
        w.writeVarint(0)
        #expect(Array(w.finish().storage) == [0x00])

        var w1 = ProtoWriter(); w1.writeVarint(1)
        #expect(Array(w1.finish().storage) == [0x01])

        var w127 = ProtoWriter(); w127.writeVarint(127)
        #expect(Array(w127.finish().storage) == [0x7F])

        var w128 = ProtoWriter(); w128.writeVarint(128)
        #expect(Array(w128.finish().storage) == [0x80, 0x01])

        var w16383 = ProtoWriter(); w16383.writeVarint(16383)
        #expect(Array(w16383.finish().storage) == [0xFF, 0x7F])

        var w16384 = ProtoWriter(); w16384.writeVarint(16384)
        #expect(Array(w16384.finish().storage) == [0x80, 0x80, 0x01])

        var wMax = ProtoWriter(); wMax.writeVarint(UInt64.max)
        #expect(Array(wMax.finish().storage) == [
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01,
        ])
    }

    // MARK: - I32 / I64

    @Test("writeI32 little-endian")
    func writeI32LE() {
        var w = ProtoWriter()
        w.writeI32(0x01020304)
        #expect(Array(w.finish().storage) == [0x04, 0x03, 0x02, 0x01])
    }

    @Test("writeI64 little-endian")
    func writeI64LE() {
        var w = ProtoWriter()
        w.writeI64(0x0102030405060708)
        #expect(Array(w.finish().storage) == [0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01])
    }

    @Test("double 1.0 round-trips through writeI64(bitPattern)")
    func writeDouble1_0() {
        var w = ProtoWriter()
        w.writeI64(Double(1.0).bitPattern)
        #expect(Array(w.finish().storage) == [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F])
    }

    // MARK: - Tag

    @Test("writeTag for field=1 wire=VARINT yields 0x08")
    func tagField1Varint() {
        var w = ProtoWriter()
        w.writeTag(field: 1, wireType: .varint)
        #expect(Array(w.finish().storage) == [0x08])
    }

    @Test("writeTag for field=15 wire=LEN yields 0x7A")
    func tagField15() {
        var w = ProtoWriter()
        w.writeTag(field: 15, wireType: .len)
        #expect(Array(w.finish().storage) == [0x7A])
    }

    @Test("writeTag for field=16 wire=LEN crosses varint boundary")
    func tagField16() {
        var w = ProtoWriter()
        w.writeTag(field: 16, wireType: .len)
        #expect(Array(w.finish().storage) == [0x82, 0x01])
    }

    // MARK: - Length-delimited

    @Test("writeLengthDelimited prepends varint length")
    func writeLenDelim() {
        var w = ProtoWriter()
        w.writeLengthDelimited(Bytes([0x68, 0x69]))
        #expect(Array(w.finish().storage) == [0x02, 0x68, 0x69])
    }
}

@Suite("ProtoWriter — field helpers")
struct ProtoWriterFieldHelperTests {
    @Test("writeUInt64 omits zero; emits non-zero")
    func uint64() {
        var w = ProtoWriter()
        w.writeUInt64(0, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])
        var w2 = ProtoWriter()
        w2.writeUInt64(42, fieldNumber: 1)
        #expect(Array(w2.finish().storage) == [0x08, 0x2A])
    }

    @Test("writeUInt32 omits zero; emits non-zero")
    func uint32() {
        var w = ProtoWriter()
        w.writeUInt32(7, fieldNumber: 4)
        #expect(Array(w.finish().storage) == [0x20, 0x07])
    }

    @Test("writeBool omits false; emits true")
    func bool() {
        var w = ProtoWriter()
        w.writeBool(true, fieldNumber: 3)
        #expect(Array(w.finish().storage) == [0x18, 0x01])
    }

    @Test("writeString omits empty; emits non-empty")
    func string() {
        var w = ProtoWriter()
        w.writeString("", fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])
        var w2 = ProtoWriter()
        w2.writeString("hi", fieldNumber: 1)
        #expect(Array(w2.finish().storage) == [0x0A, 0x02, 0x68, 0x69])
    }

    @Test("writeBytes omits empty; emits non-empty")
    func bytesField() {
        var w = ProtoWriter()
        w.writeBytes(Bytes([0xAB, 0xCD]), fieldNumber: 7)
        #expect(Array(w.finish().storage) == [0x3A, 0x02, 0xAB, 0xCD])
    }

    @Test("writeMessage emits tag+len+bytes")
    func message() {
        var w = ProtoWriter()
        w.writeMessage(Bytes([0x08, 0x01]), fieldNumber: 2)
        #expect(Array(w.finish().storage) == [0x12, 0x02, 0x08, 0x01])
    }

    @Test("writeFixed64 omits zero; emits non-zero")
    func fixed64() {
        var w = ProtoWriter()
        w.writeFixed64(1, fieldNumber: 2)
        #expect(Array(w.finish().storage) == [0x11, 0x01, 0, 0, 0, 0, 0, 0, 0])
    }

    @Test("writeFixed32 omits zero; emits non-zero")
    func fixed32() {
        var w = ProtoWriter()
        w.writeFixed32(1, fieldNumber: 16)
        // tag (16<<3)|5 = 133 = varint 0x85,0x01; fixed32 1 LE = 01 00 00 00
        #expect(Array(w.finish().storage) == [0x85, 0x01, 0x01, 0x00, 0x00, 0x00])
    }

    @Test("writeEnum omits zero; emits non-zero")
    func enumField() {
        var w = ProtoWriter()
        w.writeEnum(2, fieldNumber: 6)
        #expect(Array(w.finish().storage) == [0x30, 0x02])
    }
}
