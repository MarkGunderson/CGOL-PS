param(
    [int32]$Seed,
    [int]$Generations=0,
    [int16]$Density=10,
    [bool]$Show=$true,
    [int]$MaxFrameRate=30,
    [switch]$StartPaused,
    [int]$WindowLeftOffset=8,
    [int]$WindowTopOffset=32,
    [int]$WindowRightOffset=26,
    [int]$WindowBottomOffset=10
)
IF (-not $Seed) {
    $seed = Get-Random
}
IF ($Host.Name -ne "ConsoleHost") {
    Write-Error "Only the Console is supported. The ISE won't work."
    RETURN
}
$BGC = $host.UI.RawUI.BackgroundColor
$FGC = $host.UI.RawUI.ForegroundColor
Add-Type -AssemblyName system.windows.forms
# The following type defintion was lifted from Boe Prox's Set-Window script
# https://gallery.technet.microsoft.com/scriptcenter/Set-the-position-and-size-54853527
Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
$handle = (Get-Process -Id $pid).MainWindowHandle
Get-Random -SetSeed $Seed | Out-Null
# The MaxFrameRate parameter is purely aspirational at this point. I'm not even sure you can achieve a decent
# framerate calling $host.ui.rawui.SetBufferContents() every generation anyhow. That said, if drawing the screen
# were the bottleneck it would be a massive improvement in performance.
$Delay = [math]::round(1000/$MaxFrameRate)
# Because we're clearing the host first, replacing the buffer contents afterward is kind of moot.
# It's actually pretty easy to do, rather than calling SetBufferContents and specifying the coordinates
# as 0,0, you use 0,$host.ui.rawui.WindowPosition.Y
$BeforeCell = $host.UI.RawUI.GetBufferContents(
    [System.Management.Automation.Host.Rectangle]::new(
        0,
        $host.ui.RawUI.WindowPosition.Y,
        $host.ui.RawUI.WindowSize.width -1,
        $host.ui.RawUI.WindowSize.Height + $host.ui.RawUI.WindowPosition.Y - 1
    )
)
# fwidth and fheight are the Bool dimensions
$fWidth= $host.ui.RawUI.WindowSize.width
$fHeight = $host.UI.RawUI.WindowSize.height * 2
# Because I'm using the upper and lower parts of each character for a separate cell, it's helpful to
# save the characters ahead of time
$BCell = [System.Management.Automation.Host.BufferCell[]]::new(4)
$BCell[0] = [System.Management.Automation.Host.BufferCell]::new([char]" ",$FGC,$BGC,"Complete")
$BCell[1] = [System.Management.Automation.Host.BufferCell]::new([char]0x2580,$FGC,$BGC,"Complete")
$BCell[2] = [System.Management.Automation.Host.BufferCell]::new([char]0x2584,$FGC,$BGC,"Complete")
$BCell[3] = [System.Management.Automation.Host.BufferCell]::new([char]0x2588,$FGC,$BGC,"Complete")
# Table creation for checking when to evaluate surrounding empty squares.
# This might not result in any performance gains
<#
The script uses the following ordering for neighboring cells
012
3X4
567
#>
$Col = @()
# Each subsequent item represents a neighboring cell in spaces 0-3, and the values are the adjacent cells that
# DO NOT need to be evaluated. For example, the first item represents a neighboring living cell in the upper
# left adjacent cell. If there is a cell in the upper left, then cells 0,1,3 do not need to be evaluated for
# to see if a dead cell should come alive, as they have or will already have been evaluated in a different pass.
# By combining the values for multiple adjacent cells we can determine all of the adjacent cells that can be
# skipped. This is done below
$Col += (,[int[]](0,1,3))
$Col += (,[int[]](0,1,2,3,4))
$Col += (,[int[]](1,2,4))
$Col += (,[int[]](0,1,3,5,6))
$ENHT = @{}
# For each combination of the first four bits of a byte, store which cells NEED to be evaluated
0..15 | %{
    $HS = [System.Collections.Generic.HashSet[int]]::new()
    $Byte = $_
    0..3 | %{ 
        $Bit = $_
        IF ($Byte -band (1 -shl $Bit)) {
            $col[$Bit] | %{[void]$hs.Add($_)}
        }
    }
    $ENHT.Add($Byte,(0..7 | ?{!$hs.Contains($_)} | sort))
}
# Array of offsets, in order for the surrounding cells per the diagram above
$NeighborCoords = (-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)
# The playfield is stored in this fixed-size bool array
$Field = [bool[,]]::new($fWidth,$fHeight)
# generate random noise for the 'soup' at the beginning.
For ($y=0;$y -lt $fHeight;$y++) {
    For ($x=0;$x -lt $fWidth; $x++) {
        IF ((Get-Random -Minimum 0 -Maximum 100) -lt $Density) {
            $Field[$x,$y] = $true
        }
    }
}
# Hide the cursor by setting size to zero
$PreviousCursorSize = $host.UI.RawUI.CursorSize
$host.UI.RawUI.CursorSize = 0
# Populate and draw the buffer based on the field arraay contents
IF ($Show) {
    $Buffer = $host.ui.RawUI.NewBufferCellArray([System.Management.Automation.Host.Size]::new($host.UI.RawUI.WindowSize.width,$host.UI.RawUI.WindowSize.height),$BCell[0])
    For ($y=0;$y -lt $Host.Ui.RawUI.WindowSize.height;$y++) {
        For ($x=0;$x -lt $fWidth; $x++) {
            IF ($Field[$x,($y*2)]) {
                IF ($Field[$x,(($y*2) + 1)]) {
                    $Buffer[$y,$x] = $BCell[3]
                }
                ELSE {
                    $Buffer[$y,$x] = $BCell[1]
                }
            }
            ELSE {
                IF ($Field[$x,(($y*2) + 1)]) {
                    $Buffer[$y,$x] = $BCell[2]
                }
            }
        }
    }
    Clear-Host
    $host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$buffer)
}
ELSE {
    Write-Host "Calculating..."
}
# The first generation is calculated above
$Generation = 1
$Playing = $true
$OneFrame = $false
IF ($StartPaused) {
    $Playing = $false
}
$ExitLoop = $false
$LastDraw = Get-Date
DO {
    # Keyboard controls
    IF ([console]::KeyAvailable) {
        DO {
            $KeyPress = [System.Console]::ReadKey($true)
        } Until (![console]::KeyAvailable)
        switch ($KeyPress.key) {
            "Spacebar" {
                $Playing = !$Playing
            }
            {$_ -eq "Escape" -or $_ -eq "Q"} {
                $ExitLoop = $true
            }
            "C" {
                $Field.Clear()
                $Buffer = $host.ui.RawUI.NewBufferCellArray([System.Management.Automation.Host.Size]::new($host.UI.RawUI.WindowSize.width,$host.UI.RawUI.WindowSize.height),$BCell[0])
                $Host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$Buffer)
            }
            "r" {
                IF ($KeyPress.Modifiers -match 'Shift') {
                    Get-Random -SetSeed $Seed | Out-Null
                }
                $Field = [bool[,]]::new($fWidth,$fHeight)
                For ($y=0;$y -lt $fHeight;$y++) {
                    For ($x=0;$x -lt $fWidth; $x++) {
                        IF ((Get-Random -Minimum 0 -Maximum 100) -lt $Density) {
                            $Field[$x,$y] = $true
                        }
                    }
                }
                $Buffer = $host.ui.RawUI.NewBufferCellArray([System.Management.Automation.Host.Size]::new($host.UI.RawUI.WindowSize.width,$host.UI.RawUI.WindowSize.height),$BCell[0])
                For ($y=0;$y -lt $Host.Ui.RawUI.WindowSize.height;$y++) {
                    For ($x=0;$x -lt $fWidth; $x++) {
                        IF ($Field[$x,($y*2)]) {
                            IF ($Field[$x,(($y*2) + 1)]) {
                                $Buffer[$y,$x] = $BCell[3]
                            }
                            ELSE {
                                $Buffer[$y,$x] = $BCell[1]
                            }
                        }
                        ELSE {
                            IF ($Field[$x,(($y*2) + 1)]) {
                                $Buffer[$y,$x] = $BCell[2]
                            }
                        }
                    }
                }
                $Host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$Buffer)
            }
            "n" {
                $OneFrame = $true
            }
            "f" {
                $MousePosition = [System.Windows.Forms.Cursor]::Position
                $rect = [rect]::new()
                IF ([Window]::GetWindowRect($Handle,[ref]$Rect)) {
                    $Window = [System.Drawing.Rectangle]::FromLTRB(
                        $rect.left + $WindowLeftOffset,
                        $rect.Top + $WindowTopOffset,
                        $rect.right - $WindowRightOffset,
                        $rect.bottom - $WindowBottomOffset
                    )
                    if ($window.Contains($MousePosition.X,$MousePosition.Y)) {
                        $TileX = [math]::Ceiling($fWidth * ($MousePosition.X - $Window.Left)/$Window.Width) - 1
                        $TileY = [math]::Ceiling($fHeight * ($MousePosition.Y - $Window.Top)/$Window.Height) - 1
                        $Field[$TileX,$TileY] = !$Field[$TileX,$TileY]
                        $CharY = [math]::Floor($TileY/2)
                        IF ($TileY%2) {
                            $Bottom = $Field[$TileX,$TileY]
                            $Top = $Field[$TileX,($TileY - 1)]
                        }
                        Else {
                            $Bottom = $Field[$TileX,($TileY + 1)]
                            $Top = $Field[$TileX,$TileY]
                        }
                        If ($Top) {
                            IF ($Bottom) {
                                $BCIndex = 3
                            }
                            Else {
                                $BCIndex = 1
                            }
                        }
                        Else {
                            IF ($Bottom) {
                                $BCIndex = 2
                            }
                            Else {
                                $BCIndex = 0
                            }
                        }
                        $host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new($TileX,$CharY),$host.UI.RawUI.NewBufferCellArray(1,1,$BCell[$BCIndex]))
                    }
                }
            }
            {$_ -match "^(D\d)$"} {
                [int]$SaveSlot = $KeyPress.Key.toString().SubString(1)
                $SaveFilePath = "$($PSScriptRoot)\cgol$($SaveSlot).sav"
                $BinaryFormatter = [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new()
                IF ($KeyPress.Modifiers -match "Shift") {
                    $MS = [System.IO.MemoryStream]::new()
                    $BinaryFormatter.Serialize($MS,$Field)
                    $MS.ToArray() | Set-Content $SaveFilePath -Encoding Byte
                    $MS.Close()
                    $MS.Dispose()
                }
                ELSEIF (Test-Path $SaveFilePath) {
                    $FS = [System.IO.FileStream]::new($SaveFilePath,[System.IO.FileMode]::Open)
                    $tField = $BinaryFormatter.Deserialize($FS)
                    $FS.Close()
                    $FS.Dispose()
                    IF ($tField.GetLength(0) -eq $fWidth -and $tField.GetLength(1) -eq $fHeight) {
                        $Field = $tField.Clone()
                        $Buffer = $host.ui.RawUI.NewBufferCellArray([System.Management.Automation.Host.Size]::new($host.UI.RawUI.WindowSize.width,$host.UI.RawUI.WindowSize.height),$BCell[0])
                        For ($y=0;$y -lt $Host.Ui.RawUI.WindowSize.height;$y++) {
                            For ($x=0;$x -lt $fWidth; $x++) {
                                IF ($Field[$x,($y*2)]) {
                                    IF ($Field[$x,(($y*2) + 1)]) {
                                        $Buffer[$y,$x] = $BCell[3]
                                    }
                                    ELSE {
                                        $Buffer[$y,$x] = $BCell[1]
                                    }
                                }
                                ELSE {
                                    IF ($Field[$x,(($y*2) + 1)]) {
                                        $Buffer[$y,$x] = $BCell[2]
                                    }
                                }
                            }
                        }
                        $Host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$Buffer)
                    }

                }
            }
            {$_ -eq "OEMComma" -or $_ -eq "OEMPeriod"} {
                If ($KeyPress.Modifiers -match "Shift") {
                    IF ($KeyPress.Key -eq "OEMComma") {
                        $BGC++
                        IF ([int]$BGC -ge 16) {
                            $BGC = [System.ConsoleColor]0
                        }
                    }
                    ELSE {
                        $BGC--
                        IF ($BGC -le -1) {
                            $BGC = [System.consolecolor]15
                        }
                    }
                }
                ELSEIF ($KeyPress.Key -eq "OEMComma") {
                    $FGC++
                    IF ([int]$FGC -ge 16) {
                        [System.ConsoleColor]$FGC = 0
                    }
                }
                ELSE {
                    $FGC--
                    IF ([int]$FGC -le -1) {
                        [System.ConsoleColor]$FGC = 15
                    }
                }
                $BCell = [System.Management.Automation.Host.BufferCell[]]::new(4)
                $BCell[0] = [System.Management.Automation.Host.BufferCell]::new([char]" ",$FGC,$BGC,"Complete")
                $BCell[1] = [System.Management.Automation.Host.BufferCell]::new([char]0x2580,$FGC,$BGC,"Complete")
                $BCell[2] = [System.Management.Automation.Host.BufferCell]::new([char]0x2584,$FGC,$BGC,"Complete")
                $BCell[3] = [System.Management.Automation.Host.BufferCell]::new([char]0x2588,$FGC,$BGC,"Complete")
                $Buffer = $host.ui.RawUI.NewBufferCellArray([System.Management.Automation.Host.Size]::new($host.UI.RawUI.WindowSize.width,$host.UI.RawUI.WindowSize.height),$BCell[0])
                For ($y=0;$y -lt $Host.Ui.RawUI.WindowSize.height;$y++) {
                    For ($x=0;$x -lt $fWidth; $x++) {
                        IF ($Field[$x,($y*2)]) {
                            IF ($Field[$x,(($y*2) + 1)]) {
                                $Buffer[$y,$x] = $BCell[3]
                            }
                            ELSE {
                                $Buffer[$y,$x] = $BCell[1]
                            }
                        }
                        ELSE {
                            IF ($Field[$x,(($y*2) + 1)]) {
                                $Buffer[$y,$x] = $BCell[2]
                            }
                        }
                    }
                }
                $Host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$Buffer)
            }
        }
    }
    IF ($Playing -or $OneFrame) {
        $OneFrame = $false
        $Prev = $Field.Clone()
        $Field.Clear()
        For ($y=0;$y -lt $fHeight;$y++) {
            $PY = $Y - 1
            IF ($PY -lt 0) {
                $PY = $fHeight - 1
            }
            $NY = $y + 1
            IF ($NY -ge $fHeight) {
                $NY = 0
            }
            For ($x=0;$x -lt $fWidth; $x++) {
                IF ($prev[$x,$y]) {
                    $NeighborCount = 0
                    $NIndex = 0
                    $CheckByte = 0
                    $NeighborCoords | ForEach-Object {
                        $X1 = $x + $_[0]
                        IF ($X1 -ge $fWidth) {
                            $X1 -= $fWidth
                        }
                        $Y1 = $Y + $_[1]
                        IF ($Y1 -ge $fHeight) {
                            $Y1 -= $fHeight
                        }    
                        IF ($Prev[$x1,$y1]) {
                            $NeighborCount++
                            $CheckByte = $CheckByte -bor (1 -shl $NIndex)
                        }
                        $NIndex++
                    }
                    IF ($NeighborCount -eq 2 -or $NeighborCount -eq 3) {
                        $Field[$x,$y] = $true
                    }
                    ForEach ($CheckNeighbor in $ENHT[($CheckByte -band 15)]) {
                        $X1 = $x + $NeighborCoords[$CheckNeighbor][0]
                        IF ($X1 -ge $fWidth) {
                            $X1 -= $fWidth
                        }
                        $Y1 = $Y + $NeighborCoords[$CheckNeighbor][1]
                        IF ($Y1 -ge $fHeight) {
                            $Y1 -= $fHeight
                        }
                        IF (!$Prev[$x1,$y1]) {
                            $NeighborCount = 0
                            $NeighborCoords | ForEach-Object {
                                $Nx = $X1 + $_[0]
                                IF ($NX -ge $fWidth) {
                                    $NX -= $fWidth
                                }
                                $NY = $Y1 + $_[1]
                                IF ($NY -ge $fHeight) {
                                    $NY -= $fHeight
                                }
                                IF ($Prev[$NX,$NY]) {
                                    $NeighborCount++
                                }
                            }
                            IF ($NeighborCount -eq 3) {
                                $Field[$x1,$y1] = $true
                            }
                        }
                    }
                }
            }
        }
        IF ($show) {
            $Buffer = $host.ui.RawUI.NewBufferCellArray([System.Management.Automation.Host.Size]::new($host.UI.RawUI.WindowSize.width,$host.UI.RawUI.WindowSize.height),$BCell[0])
            For ($y=0;$y -lt $Host.Ui.RawUI.WindowSize.height;$y++) {
                For ($x=0;$x -lt $fWidth; $x++) {
                    IF ($Field[$x,($y*2)]) {
                        IF ($Field[$x,(($y*2) + 1)]) {
                            $Buffer[$y,$x] = $BCell[3]
                        }
                        ELSE {
                            $Buffer[$y,$x] = $BCell[1]
                        }
                    }
                    ELSE {
                        IF ($Field[$x,(($y*2) + 1)]) {
                            $Buffer[$y,$x] = $BCell[2]
                        }
                    }
                }
            }
            $SinceLastDraw = (New-TimeSpan $LastDraw).TotalMilliseconds
            IF ($SinceLastDraw -lt $Delay) {
                Start-Sleep -Milliseconds ($Delay - $SinceLastDraw)
            }
            $LastDraw = Get-Date
            $host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$buffer)
        }
        $Generation++
    }
    ELSE {
        Start-Sleep -Milliseconds 5
    }
} UNTIL (($Generation -ge $Generations -and $Generations -gt 0) -or $ExitLoop)
$host.UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new(0,0),$buffer)
Write-Host "S:$($Seed),D:$($density)."
$host.UI.RawUI.CursorSize = $PreviousCursorSize
