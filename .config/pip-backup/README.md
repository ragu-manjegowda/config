# Manage pip packages

## Backup

```shell
pip freeze > requirements.txt
```

## Restore

```shell
pip install -r requirements.txt
```

## Upgrade

```shell
pip list --outdated --format=columns | awk 'NR>2 {print $1}' | xargs -n1 pip install -U
```
