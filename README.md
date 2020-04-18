# CGOL-PS
Conway's Game of Life in PowerShell

![screen](/img/duelinggospergliderguns.png)

A limited version of Conway's Game of Life written in PowerShell.

Features:
* Mere orders of magnitude less performant than proper GoL implementations
* Uses the buffer to look kind of okay
* Pseudo mouse support for editing
* 10 save slots for all those spicy patterns
* Change colors! Background and foreground!

Run the script specifying parameters as necessary

Space: Pause/Unpause

f: Pseudo mouse click to toggle cell status. Move the mouse and tap F to edit.

n: Clear Field

r: Randomize the field

R: Set the field to the initial randomized state for this session (i.e., reset the random seed)

n: Advance once generation while paused

Shift + Number Keys: Save field state 

Number keys: Load save state

, .: Cycle Live Cell Color

< >: Cycle Dead Cell Color

Window position type info gratefully borrowed from https://gallery.technet.microsoft.com/scriptcenter/Set-the-position-and-size-54853527

Planned changes:
* Replace redundant sections with functions
* Infinite play field support and performance improvements. Maybe just replace the engine with a bit of c# and Add-Type? Does this defeat the purpose?
* Mouse clicks and in-game calibration if necessary
* Hashing of each generation to identify if a pattern stabilizes and in how many generations
* Functions to import/export common GOL pattern notation or file formats e.g., RLE, plaintext, or possibly monochrome images
