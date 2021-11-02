# Migrate homebrew


## Backup existing homebrew formulas

```
$ ./.backup-homebrew.sh > .restore-homebrew_{OS}.sh
$ chmod u+x .restore-homebrew_{OS}.sh
```

## Install homebrew on new machine

```
$ mkdir homebrew && \
  curl -L https://github.com/Homebrew/brew/tarball/master | \
  tar xz --strip 1 -C homebrew
```

## Restore homebrew formulas

```
./.restore-homebrew_{OS}.sh
```

