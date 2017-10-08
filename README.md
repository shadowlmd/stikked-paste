# stikked-paste
### Another command line client for [Stikked](https://github.com/claudehohl/Stikked)

It will try to detect language of pasted content and copy link to clipboard.

Reads configuration from `$HOME/.stikked` file. Example can be found in this repo.

Usage examples:
* `some-command | stikked.sh [language]`
* `stikked.sh [/path/to/]some-file`

Optional arguments:
* `-l|--lang|--language <language>`
* `-e|--expire <expiration>`
* `-p|-f|--permanent|--forever`
* `--private`
* `--noclip`
