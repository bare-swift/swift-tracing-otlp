// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import OTLPExporter

extension OTLP {
    /// `opentelemetry.proto.trace.v1.Span`.
    public struct Span: Sendable, Equatable {
        public enum Kind: UInt32, Sendable, Equatable {
            case unspecified = 0
            case `internal` = 1
            case server = 2
            case client = 3
            case producer = 4
            case consumer = 5
        }

        /// `opentelemetry.proto.trace.v1.Span.Event`. Encoded in EncodeTraces.
        public struct Event: Sendable, Equatable {
            public var timeUnixNano: UInt64
            public var name: String
            public var attributes: [KeyValue]
            public var droppedAttributesCount: UInt32

            public init(
                timeUnixNano: UInt64 = 0,
                name: String = "",
                attributes: [KeyValue] = [],
                droppedAttributesCount: UInt32 = 0
            ) {
                self.timeUnixNano = timeUnixNano
                self.name = name
                self.attributes = attributes
                self.droppedAttributesCount = droppedAttributesCount
            }
        }

        /// `opentelemetry.proto.trace.v1.Span.Link`. Encoded in EncodeTraces.
        public struct Link: Sendable, Equatable {
            public var traceID: Bytes
            public var spanID: Bytes
            public var traceState: String
            public var attributes: [KeyValue]
            public var droppedAttributesCount: UInt32
            public var flags: UInt32

            public init(
                traceID: Bytes = Bytes(),
                spanID: Bytes = Bytes(),
                traceState: String = "",
                attributes: [KeyValue] = [],
                droppedAttributesCount: UInt32 = 0,
                flags: UInt32 = 0
            ) {
                self.traceID = traceID
                self.spanID = spanID
                self.traceState = traceState
                self.attributes = attributes
                self.droppedAttributesCount = droppedAttributesCount
                self.flags = flags
            }
        }

        public var traceID: Bytes
        public var spanID: Bytes
        public var traceState: String
        public var parentSpanID: Bytes
        public var name: String
        public var kind: Kind
        public var startTimeUnixNano: UInt64
        public var endTimeUnixNano: UInt64
        public var attributes: [KeyValue]
        public var droppedAttributesCount: UInt32
        public var events: [Event]
        public var droppedEventsCount: UInt32
        public var links: [Link]
        public var droppedLinksCount: UInt32
        public var status: Status
        public var flags: UInt32

        public init(
            traceID: Bytes = Bytes(),
            spanID: Bytes = Bytes(),
            traceState: String = "",
            parentSpanID: Bytes = Bytes(),
            name: String = "",
            kind: Kind = .unspecified,
            startTimeUnixNano: UInt64 = 0,
            endTimeUnixNano: UInt64 = 0,
            attributes: [KeyValue] = [],
            droppedAttributesCount: UInt32 = 0,
            events: [Event] = [],
            droppedEventsCount: UInt32 = 0,
            links: [Link] = [],
            droppedLinksCount: UInt32 = 0,
            status: Status = Status(),
            flags: UInt32 = 0
        ) {
            self.traceID = traceID
            self.spanID = spanID
            self.traceState = traceState
            self.parentSpanID = parentSpanID
            self.name = name
            self.kind = kind
            self.startTimeUnixNano = startTimeUnixNano
            self.endTimeUnixNano = endTimeUnixNano
            self.attributes = attributes
            self.droppedAttributesCount = droppedAttributesCount
            self.events = events
            self.droppedEventsCount = droppedEventsCount
            self.links = links
            self.droppedLinksCount = droppedLinksCount
            self.status = status
            self.flags = flags
        }
    }

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
