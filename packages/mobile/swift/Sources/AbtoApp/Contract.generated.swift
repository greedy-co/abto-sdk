// GENERATED FILE — DO NOT EDIT.

public let abtoSchemaVersion = "2026-09-02"
package let abtoDefaultCollectEndpoint = "https://api.abto.app/v1/collect/events"
public let abtoDefaultBatchSize = 20
package let abtoMinBatchSize = 1
public let abtoDefaultFlushInterval: Double = 5
package let abtoErrProjectKeyRequired = "[abto] projectKey is required. Check your init config."
package let abtoErrEndpointHTTPSRequired = "[abto] endpoint must use HTTPS outside development loopback."
package let abtoErrEndpointInvalidPrefix = "[abto] endpoint is not a valid http(s) URL: "
package let abtoErrBatchSizeRange = "[abto] batchSize must be between 1 and 100."
package let abtoErrInteractionDropped = "[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions."
let abtoEventNameMaxLength = 200
package let abtoMaxBufferedEvents = 1000
package let abtoMaxRetryDelay: Double = 120
package let abtoRetryJitterRatio = 0.5
package let abtoMaxAttempts = 5
package let abtoMaxEventAge: Double = 1800
package let abtoMaxBatchSize = 100
let abtoReservedEventNames: Set<String> = ["pageview", "pageleave", "interaction_autocaptured", "interaction_rageclick", "interaction_deadclick", "llm_prompt_submitted", "llm_response_rendered", "llm_response_interacted"]

public enum AbtoResponseInteraction: String, CaseIterable, Sendable {
    case copied = "copied"
    case inserted = "inserted"
    case accepted = "accepted"
    case rejected = "rejected"
    case shared = "shared"
    case downloaded = "downloaded"
    case expanded = "expanded"
    case collapsed = "collapsed"
    case ratedPositive = "rated_positive"
    case ratedNegative = "rated_negative"
    case regenerated = "regenerated"
    case aborted = "aborted"
}
