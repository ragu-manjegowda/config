# Manage pip packages

## Backup

```shell
pip list --not-required --format=freeze > requirements.txt
```

## Restore

```shell
pip install -r requirements.txt
```

## Upgrade

```shell
pip list --not-required --format=freeze | cut -d= -f1 | xargs -n 1 pip install --upgrade
```
