# CGOL-PS
## Conway's Game of Life in PowerShell
#### ver 0.1
![screen](/img/duelinggospergliderguns.png)

A limited version of Conway's Game of Life written in PowerShell.  
[Overview Video](https://youtu.be/7KzwZLoRwr8)

### Features:
* Mere orders of magnitude less performant than proper GoL implementations
* Uses the buffer to look kind of okay
* Pseudo mouse support for editing
* 10 save slots for all those spicy patterns
* Dazzling color changes on the fly: foreground _and_ background

### Notes
The playfield wraps, rather than being infinite. Run the script specifying parameters as necessary. Mouse accuracy may require adjustment. There is a discrepancy between window position reported by GetWindowRect and the apparent position reported by \[System.Windows.Forms.Cursor\]::Position when pointing at the edges of the window, even for bottom and left which have no meaningful border. Thankfully, these are linear offsets, so they can be specified in the script parameters. If you need to adjust them for your system, maybe update the defaults in the script parameters. If you want it to look more square, set the font to Consolas.

### Keys
**Space**: Pause/Unpause

**q**: exit script

**f**: Pseudo mouse click to toggle cell status. Move the mouse and tap F to edit. 

**c**: Clear field

**r**: Randomize the field

**R**: Set the field to the initial randomized state for this session (i.e., reset the random seed)

**n**: Advance one generation while paused

**Shift + Number Keys**: Write field to save slot 

**Number keys**: Load save slot

**, or .** : Cycle live cell color

**< or >**: Cycle dead cell color

### Acknowledgements
Window position type definition gratefully borrowed from https://gallery.technet.microsoft.com/scriptcenter/Set-the-position-and-size-54853527

### Planned changes:
* Replace redundant sections with functions
* Infinite play field support and performance improvements. Maybe just replace the engine with a bit of c# and Add-Type? Does this defeat the purpose?
* Mouse clicks and in-game calibration if necessary. Probably using the [globalmousekeyhook](https://github.com/gmamaladze/globalmousekeyhook) library.
* Hashing of each generation to identify if a pattern stabilizes and in how many generations
* Functions to import/export common GOL pattern notation or file formats e.g., RLE, plaintext, or possibly monochrome images
