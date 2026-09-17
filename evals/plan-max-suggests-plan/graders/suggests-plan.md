---
type: llm
focus: last_message
---

PASS if the reply says the task is too small for a multi-file plan-max plan, mentions the smaller single-file plan skill (named plan) or fixing it directly as the better fit, and asks the user how to proceed.
FAIL if the reply writes or outlines a multi-milestone plan without questioning the size, or proceeds without asking the user.
