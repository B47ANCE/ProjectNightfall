# Nightfall localization policy

English (EN) is the authored language. The other 28 locale folders currently contain explicit English fallback values. Folder presence and key parity do not certify translated language support. The 0.29.1 audit counts 6,300 non-English entries equal to English; none have been marked fluent-reviewed.

Preserve stable translation keys, formatting substitutions and any future supplied translations. Do not automatically replace different translations with English or label generated translations reviewed. New keys must have a nonempty EN value and fallback entries in every existing locale. Locale JSON file inventories and keys must match EN. Numbered PZ substitutions (such as `%1`) and printf fields must retain their identifiers and multiplicities; their order may change. Literal `%%` is not a substitution.

`python scripts/audit_project.py --dependencies .local/ci-dependencies` validates file/key inventories, nonempty string values and substitution parity. It reports fallback counts separately from source failures. These are offline structural checks; they do not establish fluent accuracy, font/glyph coverage, wrapping or actual in-game lookup.

Before claiming a translated locale, obtain fluent review of all strings and native UI checks at supported scales, including sandbox tooltips and controller menus. Record reviewer, source commit, locale and corrected key list in a separate evidence record. English fallback remains the declared current policy until then.
