# Description
A command where players can request to extend the current map time. Tested only in CS:GO. Might work on another games.

# Alliedmods
https://forums.alliedmods.net/showthread.php?t=320078

# Commands
```
sm_extend (console), !extend or /extend (chat)
extend (chat)
```

# ConVars
```
sm_extendmap_extendtime 10 // The current map will be extended with this much time.
sm_extendmap_maxextends 1 // If set, how many times players can extend the current map?
sm_extendmap_minplayers 1 // Number of players required before the extend command will be enabled.
sm_extendmap_percentagereq 0.60 // Percentage of players required to extend the current map (def 60%)
sm_extendmap_extendcurrentround 0 // Extend the current round as well? (for deathmatch servers where timelimit = roundtime)
```
