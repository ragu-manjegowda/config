# Manage pip packages

## Restore
```shell
mkdir -p ~/.local/share/npm
echo "prefix=${HOME}/.local/share/npm" >> ~/.npmrc

xargs -a ~/.config/npm-backup/package.in -I {} npm install --prefix "$HOME/.local/share/npm" {}
```
