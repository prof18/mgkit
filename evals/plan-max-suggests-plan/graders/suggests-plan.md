---
type: llm
focus: last_message
---

PASS if the reply says the task is too small for a multi-file plan, recommends the smaller single-file plan skill (named plan) with a reason, and asks the user whether to switch.
FAIL if the reply writes or outlines a multi-milestone plan without questioning the size, or switches without asking.
