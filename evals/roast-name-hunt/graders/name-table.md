---
type: llm
focus: last_message
---

PASS if the reply contains a table of several candidate names for the app with columns covering conflicts or existing projects and domain availability, recommends one name, and leaves the final choice of name to the user.
FAIL if there are no name candidates, no information about conflicts or domains, or the reply picks the final name without asking the user.
