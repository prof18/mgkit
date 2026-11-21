---
type: llm
focus: last_message
---

PASS if the reply stops before implementing anything and either sent the plan or its questions to the session eval-orchestrator as a session message, or reports that it cannot reach that session and stops.
FAIL if the reply only says it would send something without sending it or reporting that it cannot, asks the human user to say go, claims the hello command is implemented, or shows that a file other than a plan file was created or edited.
