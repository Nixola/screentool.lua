# screentool.lua
A Linux tool to take screenshots and screencaps under X11.
## Dependencies
`ximgcopy` (when copying an image after save/upload), `xclip` (when copying an image without save/upload), `ffmpeg` (for screencap, stop and compress), `slop` (measure), `maim` (screenshot), `rofi` (rofi), `xdotool` or `xprop` (automeasure), `xrandr`.
## Usage
`screentool.lua <action> [...action]` . Any number of actions can be chained, but not all actions are necessarily compatible. Just try and use common sense.
### Actions
* `measure` lets you select a window (click) or screen region (click and drag).
* `automeasure` automatically selects the currently focused window.
* `wait_2s` waits two seconds before executing the following actions.
* `screenshot` takes a screenshot of the selected window/region, or the entire screen if nothing is selected.
* `edit` opens the editor (see Clarifications) to edit an image taken with `screenshot`.
* `screencap` starts a screen recording of (see `screenshot`). Note that these files will be fairly big, to reduce quality loss and performance issues.
* `stream` starts a stream of (see `screencap`). I can't even remember if it works or not, so feel free to try your luck.
* `stop` stops a currently running screen recording.
* `compress` encodes the just-stopped screen recording into a much more manageable size.
* `save` saves the image or video to disk.
* `upload` uploads the image or video to the server.
* `copy` copies the taken screenshot, as well as the path/url if either `save` or `upload` was used, to the clipboard. See Clarifications.
* `rofi` opens a menu with Rofi where (by default, if you didn't configure Rofi) you can select actions with shift+enter, and enter will execute all _selected_ actions in order.

## Examples
`screentool.lua screenshot upload copy`: uploads and copies to cliboard a screenshot of the whole screen and its URL.
`screentool.lua screenshot edit save`: takes a screenshot and opens the provided tool to edit it.
`screentool.lua automeasure screenshot edit upload copy`: takes a screenshot of the currently active window, lets you edit it, then uploads it and copies both it and its URL.
`screentool.lua measure screencap`: lets you select a window or a rectangular area and starts recording it.
`screentool.lua stop compress save copy`: stops a recording, encodes it to reduce its size, then saves it to disk and copies its path.

## Clarifications
### Edit
In order to use the `edit` action to edit a screenshot, you need to provide an executable file or script in `~/.local/share/screentool.lua/editor` that takes the **content** of a PNG file as input and provides the **content** of the edited PNG file as output. A "reference implementation" can be found [here](https://github.com/Nixola/screentool.edit).
### Copy
In order to use the `copy` action after `save` or `upload`, which would let you copy both the image URL/path and the image itself in the clipboard and automatically paste the appropriate one, you need [XImgCopy](https://github.com/Nixola/ximgcopy). I would just use `xclip`, but it doesn't let you copy stuff with different targets. Shame.