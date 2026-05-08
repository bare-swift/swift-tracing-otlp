// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import TracingOTLP

@Suite("TracingOTLPError")
struct TracingOTLPErrorTests {
    @Test("TracingOTLPError is Sendable and Error (uninhabited type — reserved)")
    func conformances() {
        let _: any Error.Type = TracingOTLPError.self
        let _: any Sendable.Type = TracingOTLPError.self
    }
}
