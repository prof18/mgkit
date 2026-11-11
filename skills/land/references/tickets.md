# Tickets

A ticket is the task note, board card or issue a piece of work came from. `quick` and `build` move it to in progress when the work starts. `land` marks it done when the work is merged.

## Find the ticket

Look in this order:

1. What the conversation already gives: a ticket path, link or id passed to the skill, or mentioned when the work started.
2. The user's or repository's instructions, which may say where tickets live and which status values they use.
3. Only when landing: a search of that location for the branch topic or commit subject.

- If there is no clear single match, ask. Never guess a ticket.
- At the start of work, never search for a ticket. If the request names none, there is none: skip the ticket step without saying anything.
- When landing, if the work has no ticket, skip the ticket step and say so.

## Know the status value

Take the value that means in progress or done for this tracker from the user's or repository's instructions, or from the board's own configuration, such as its column order. Write it exactly as the tracker spells it. If you cannot tell, ask once.

## Change the status

- **Local note or file.** Change only the status field. Leave every other field as it is.
- **Hosted tracker** (an issue on GitHub, a ticket in a project tool). Changing it is visible to others, so ask before you move or close it, unless the user already asked for that in this conversation or in their instructions.
- **Start of work.** Move the ticket to in progress before the first change to the code or the first plan file. If the ticket already has that status or a later one, leave it. Say in one line that the ticket moved.
- **Landing.** Mark the ticket done.
