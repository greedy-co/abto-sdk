// GENERATED FILE — DO NOT EDIT.

const abtoSchemaVersion = "2026-09-02";
const abtoEventNameMaxLength = 200;
const abtoReservedEventNames = <String>{"pageview", "pageleave", "interaction_autocaptured", "interaction_rageclick", "interaction_deadclick", "llm_prompt_submitted", "llm_response_rendered", "llm_response_interacted"};

extension type const AbtoResponseInteraction._(String wireValue) implements String {
  static const copied = AbtoResponseInteraction._("copied");
  static const inserted = AbtoResponseInteraction._("inserted");
  static const accepted = AbtoResponseInteraction._("accepted");
  static const rejected = AbtoResponseInteraction._("rejected");
  static const shared = AbtoResponseInteraction._("shared");
  static const downloaded = AbtoResponseInteraction._("downloaded");
  static const expanded = AbtoResponseInteraction._("expanded");
  static const collapsed = AbtoResponseInteraction._("collapsed");
  static const ratedPositive = AbtoResponseInteraction._("rated_positive");
  static const ratedNegative = AbtoResponseInteraction._("rated_negative");
  static const regenerated = AbtoResponseInteraction._("regenerated");
  static const aborted = AbtoResponseInteraction._("aborted");

  static const values = <AbtoResponseInteraction>[
    copied,
    inserted,
    accepted,
    rejected,
    shared,
    downloaded,
    expanded,
    collapsed,
    ratedPositive,
    ratedNegative,
    regenerated,
    aborted,
  ];

  static AbtoResponseInteraction? fromWireValue(String value) {
    for (final interaction in values) {
      if (interaction.wireValue == value) return interaction;
    }
    return null;
  }
}
