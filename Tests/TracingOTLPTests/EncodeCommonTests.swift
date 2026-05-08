// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter
import Bytes

@Suite("AnyValue encoding (re-implementation; matches OTLPExporter wire output)")
struct AnyValueEncodingTests {
    @Test("string \"v\" → field 1 (LEN)")
    func string() {
        let bytes = EncodeCommon.encodeAnyValue(.string("v"))
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x76])
    }

    @Test("bool true → field 2")
    func boolTrue() {
        let bytes = EncodeCommon.encodeAnyValue(.bool(true))
        #expect(Array(bytes.storage) == [0x10, 0x01])
    }

    @Test("int 1 → field 3")
    func intOne() {
        let bytes = EncodeCommon.encodeAnyValue(.int(1))
        #expect(Array(bytes.storage) == [0x18, 0x01])
    }

    @Test("double 1.0 → field 4 (I64 wire type)")
    func doubleOne() {
        let bytes = EncodeCommon.encodeAnyValue(.double(1.0))
        #expect(Array(bytes.storage) == [0x21, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
    }

    @Test("bytes [0xAB] → field 7")
    func bytesField() {
        let bytes = EncodeCommon.encodeAnyValue(.bytes(Bytes([0xAB])))
        #expect(Array(bytes.storage) == [0x3A, 0x01, 0xAB])
    }

    @Test("array [int(1)] → field 5 (LEN message)")
    func arrayOfInt() {
        let bytes = EncodeCommon.encodeAnyValue(.array([.int(1)]))
        #expect(Array(bytes.storage) == [0x2A, 0x04, 0x0A, 0x02, 0x18, 0x01])
    }

    @Test("kvlist [(k, string(v))] → field 6")
    func kvlist() {
        let bytes = EncodeCommon.encodeAnyValue(.kvlist([
            OTLP.KeyValue(key: "k", value: .string("v"))
        ]))
        let expected: [UInt8] = [
            0x32, 0x0A,
            0x0A, 0x08,
            0x0A, 0x01, 0x6B,
            0x12, 0x03, 0x0A, 0x01, 0x76,
        ]
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("KeyValue encoding (re-implementation)")
struct KeyValueEncodingTests {
    @Test("KeyValue(key: \"k\", value: .string(\"v\"))")
    func basic() {
        let bytes = EncodeCommon.encodeKeyValue(OTLP.KeyValue(key: "k", value: .string("v")))
        #expect(Array(bytes.storage) == [
            0x0A, 0x01, 0x6B,
            0x12, 0x03, 0x0A, 0x01, 0x76,
        ])
    }
}

@Suite("Resource encoding (re-implementation)")
struct ResourceEncodingTests {
    @Test("empty Resource encodes to empty bytes")
    func empty() {
        let bytes = EncodeCommon.encodeResource(OTLP.Resource())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Resource with one attribute KeyValue(\"k\", string(\"v\"))")
    func oneAttribute() {
        let res = OTLP.Resource(attributes: [
            OTLP.KeyValue(key: "k", value: .string("v"))
        ])
        let bytes = EncodeCommon.encodeResource(res)
        #expect(Array(bytes.storage) == [
            0x0A, 0x08,
            0x0A, 0x01, 0x6B,
            0x12, 0x03, 0x0A, 0x01, 0x76,
        ])
    }
}

@Suite("InstrumentationScope encoding (re-implementation)")
struct InstrumentationScopeEncodingTests {
    @Test("scope with name=\"x\", version=\"1\"")
    func nameAndVersion() {
        let s = OTLP.InstrumentationScope(name: "x", version: "1")
        let bytes = EncodeCommon.encodeInstrumentationScope(s)
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x78, 0x12, 0x01, 0x31])
    }
}
