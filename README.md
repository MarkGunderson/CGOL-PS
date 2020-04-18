# CGOL-PS
Conway's Game of Life in PowerShell

A limited version of Conway's Game of Life written in PowerShell that sacrifices mere orders of magnitude in performance versus a proper implementation. The game field is not infinite, it wraps around. Each console character represents an upper and lower cell, resulting in double the vertical resolution.

Run the script specifying parameters as necessary

Space: Pause/Unpause

C: Clear Field

N: Advance once generation while paused

F: Pseudo mouse click to toggle cell status

Shift + Number Keys: Save field state 

Number keys: Load save state

, .: Cycle Live Cell Color

< >: Cycle Dead Cell Color

Window position type info gratefully borrowed from https://gallery.technet.microsoft.com/scriptcenter/Set-the-position-and-size-54853527
