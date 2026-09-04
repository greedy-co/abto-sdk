// GENERATED FILE — DO NOT EDIT.

package app.abto.sdk

const val ABTO_SCHEMA_VERSION = "2026-09-02"
const val ABTO_EVENT_NAME_MAX_LENGTH = 200
const val ABTO_MAX_BUFFERED_EVENTS = 1000
const val ABTO_MAX_RETRY_DELAY_MS = 120000L
const val ABTO_RETRY_JITTER_RATIO = 0.5
const val ABTO_MAX_ATTEMPTS = 5
const val ABTO_MAX_EVENT_AGE_MS = 1800000L
const val ABTO_MAX_BATCH_SIZE = 100
const val ABTO_MAX_RESPONSE_BYTES = 65536
val ABTO_RESERVED_EVENT_NAMES = setOf("pageview", "pageleave", "interaction_autocaptured", "interaction_rageclick", "interaction_deadclick", "llm_prompt_submitted", "llm_response_rendered", "llm_response_interacted")

enum class AbtoResponseInteraction(val wireValue: String) {
    COPIED("copied"),
    INSERTED("inserted"),
    ACCEPTED("accepted"),
    REJECTED("rejected"),
    SHARED("shared"),
    DOWNLOADED("downloaded"),
    EXPANDED("expanded"),
    COLLAPSED("collapsed"),
    RATED_POSITIVE("rated_positive"),
    RATED_NEGATIVE("rated_negative"),
    REGENERATED("regenerated"),
    ABORTED("aborted");

    companion object {
        fun fromWireValue(value: String): AbtoResponseInteraction? = entries.firstOrNull { it.wireValue == value }
    }
}
