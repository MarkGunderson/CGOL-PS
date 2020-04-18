# CGOL-PS
Conway's Game of Life in PowerShell

![screen](/img/duelinggospergliderguns.png)

A limited version of Conway's Game of Life written in PowerShell that sacrifices mere orders of magnitude in performance versus a proper implementation. The field is finite, wrapping at the edges. Each console character represents an upper and lower cell, resulting in double the vertical resolution.

Pseudo mouse support is included for editing cells. If the positioning is off, you may need to adjust the window offset parameters (when you find them, go ahead and update the defaults in the script for your system).

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
