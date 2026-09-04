// GENERATED FILE — DO NOT EDIT.

public let abtoSchemaVersion = "2026-09-02"
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
