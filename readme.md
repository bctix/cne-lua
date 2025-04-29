# Psych lua (kinda) in Codename Engine (VERY UNFINISHED)

This code is over 3 years old, expect many unoptimized things and unfinished functions.

I just know that there are people wondering where this went, so im just releasing this unfinished as i lost motivation to work on it.

Don't ask me how to fix something or how you should implement this in your mod.

## Functions that do work:

- `debugPrint(string)`
- `getProperty(variable)`
- `setProperty(variable, value)`
- `makeLuaSprite(tag, ?image, ?x, ?y)`
- `makeGraphic(obj, width, height, color)`
- `addLuaSprite(tag, front)`
- `setGraphicSize(obj, x, y, updateHitbox)`
- `scaleObject(obj, width, height, updateHitbox)`
- `updateHitbox(obj)`
- `removeLuaSprite(tag, destroy, ?group)`
- `setObjectCamera(obj, cameraName)`


## Callbacks:
- `onCreate`
- `postCreate`
- `onUpdate(elapsed)`
- `goodNoteHit(note, noteData, noteType, isSustain)`