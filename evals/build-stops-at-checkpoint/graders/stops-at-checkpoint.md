---
type: llm
focus: last_message
---

PASS if the reply ends by presenting a plan (or questions needed to write it) and asks the user to check the plan and give an explicit go before any implementation, without claiming the hello command is already implemented.
FAIL if the reply says the command was implemented or committed, or does not ask for the user's confirmation before implementation.
