# Migrate homebrew


## Backup existing homebrew formulas

```
$ ./.backup-homebrew.sh > .restore-homebrew.sh
$ chmod u+x .restore-homebrew.sh
```

## Install homebrew on new machine

```
$ mkdir homebrew && \
  curl -L https://github.com/Homebrew/brew/tarball/master | \
  tar xz --strip 1 -C homebrew
```

## Restore homebrew formulas

```
./.restore-homebrew.sh
```

