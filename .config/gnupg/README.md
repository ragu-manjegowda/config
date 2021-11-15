
# Instructions to generate and copy gpg keys.

1. After installing gpg (if it does not exist), delete ~/.gpg.
2. Generate GPG key
    ```sh
    $ gpg --gen-key
    ```

## Copying keys

1. On first machine export keys

```sh
$ gpg --export KEY_ID > gpg.key
$ gpg --export-secret-keys KEY_ID > gpg_secret.key
```

2. On second machine copy them

```sh
$ ssh USER@IP "cat gpg.key" | gpg --import
$ ssh USER@IP "cat gpg_secret.key" | gpg --import
```

## Issues

1. If git commit failed
    * Run `GIT_TRACE=1 GIT_COMMAND`
    * Run the trace commands manually
    * Fix the issues ;)

2. If there is time-out error when importing key over ssh
    * This is probably because password is requested over pop-up (gnome3).
    Change the pinentry to use ncurses so that prompt shows up in console
        ```sh
        $ sudo update-alternatives --config pinentry
        ```
    * Alternatively command line parameter `--pinentry-mode loopback` can also
    be used.

