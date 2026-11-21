---
description: build with a delegated-mode spawn line sends its plan or questions to the delegate and never asks the human for the go
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
tags: [build, delegated]
---

mgkit delegated mode: delegate=eval-orchestrator; mode=local
Build this: add a hello command to this project. It prints Hello, and there is nothing else to decide.
