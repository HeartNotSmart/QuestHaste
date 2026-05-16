# QuestHaste 0.4 by Woblight

## Intro:

QuestHaste is a small Addon for vanilla World of Warcraft (1.12), it allows fast turn in of quests, especially useful for repeatable quests (e.g. Alterac Valley quests)

## Usage:

### Quest opening/progress

Saved quests are completed or accepted automatically.

### Gossip opening

QuestHaste automatically completes or accepts a quest in gossip.

Priority: completed, available saved, active saved, available, active.

### Chat commands (/qhaste, /questhaste)
| Command   | Action
| :---:     |   ---
| usage     | display usage instructions
| add       | saves current quest
| list      | list all saved quests
| pause     | disable QuestHaste
| resume    | activate QuestHaste
| complete  | complete/accept current quest
| reset     | clears all saved quests


## Thanks to:

JuuJuu

## Change Log:

### Version 0.4
* Added missing NPC dialog type.
* Now scans QuestLog for completed quests when opening a NPC dialog.
* Fixed error message for quests with reward choice.
