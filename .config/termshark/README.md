# Termshark on MacOS

Default location on MacOS is ~/Library/Application Support/termshark, hence
delete the file if it exists and symlink to ~/.config/termshark.

```shell
$ rm -rf ~/Library/Application\ Support/termshark
$ ln -s ~/.config/termshark ~/Library/Application\ Support/termshark
```
