# screentool.lua
A Linux tool to take screenshots and screencaps under X11.
## Dependencies
`ximgcopy` (when copying an image after save/upload), `ffmpeg` (for screencap, stop and compress), `slop` (measure), `maim` (screenshot), `xrandr`, `rofi` (rofi).
## Usage
`screentool.lua <action> [...action]`  
### Actions
* `measure`
* `screenshot`
* `screencap`
* `stop`
* `compress`
* `edit`
* `save`
* `upload`
* `copy`
## Examples
`screentool.lua screenshot upload copy`: uploads and copies to cliboard a screenshot of the whole screen.
`screentool.lua screenshot edit save`: takes a screenshot and opens the provided tool to edit it.
`screentool.lua measure screencap`: lets you select a window or a rectangular area and starts recording it.
`screentool.lua stop compress save copy`: stops a recording, encodes it to reduce its size, then saves it to disk and copies its path.

## Modes
### Edit
In order to use the `edit` action to edit a screenshot, you need to provide an executable file in `~/.local/share/screentool.lua/editor` that takes the **content** of a PNG file as input and provides the **content** of the edited PNG file as output.
