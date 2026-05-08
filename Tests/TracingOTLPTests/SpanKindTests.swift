// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP
import OTLPExporter

@Suite("SpanKind raw values")
struct SpanKindTests {
    @Test("SpanKind matches proto: unspecified=0, internal=1, server=2, client=3, producer=4, consumer=5")
    func rawValues() {
        #expect(OTLP.Span.Kind.unspecified.rawValue == 0)
        #expect(OTLP.Span.Kind.internal.rawValue == 1)
        #expect(OTLP.Span.Kind.server.rawValue == 2)
        #expect(OTLP.Span.Kind.client.rawValue == 3)
        #expect(OTLP.Span.Kind.producer.rawValue == 4)
        #expect(OTLP.Span.Kind.consumer.rawValue == 5)
    }
}
