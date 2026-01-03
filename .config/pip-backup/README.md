# Manage pip packages

## Using uv

### Restore
```shell
uv venv --system-site-packages ~/.local/share/venv
uv pip install -r requirements.in --python ~/.local/share/venv/bin/python
```

### Upgrade
```shell
uv pip install -r requirements.in --upgrade
```
