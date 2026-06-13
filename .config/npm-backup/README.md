# Manage npm packages

## Restore
```shell
mkdir -p ~/.local/share/npm
echo "prefix=${HOME}/.local/share/npm" >> ~/.npmrc

xargs -a ~/.config/npm-backup/packages.in -I {} npm install -g {}
```

Package-specific tool install/upgrade commands live in `package-tools.in`.
