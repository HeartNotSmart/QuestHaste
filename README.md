# QuestHaste 0.4 by Woblight

## Intro:

QuestHaste is a small Addon for vanilla World of Warcraft (1.12), it allows fast turn in of quests, especially useful for repeatable quests (e.g. Alterac Valley quests)

## Usage:

### Quest (active and available) opening/progress

QuestHaste automatically accepts and completes quests when possible.
Hold Shift when starting an NPC interaction to pause automation for that interaction.

### Gossip opening modifiers

| Modifier      | Action
| :---:         | ---
| Shift         | pause automation for this interaction
| None          | auto complete/accept quest in gossip  
|               | (priority: completed, available, active)

### Chat commands (/qhaste, /questhaste)
| Command   | Action
| :---:     |   ---
| usage     | display usage instructions
| pause     | disable QuestHaste
| resume    | activate QuestHaste
| complete  | complete/accept current quest


## Thanks to:

JuuJuu

## Change Log:

### Version 0.4
* Added missing NPC dialog type.
* Now scans QuestLog for completed quests when opening a NPC dialog.
* Fixed error message for quests with reward choice.
