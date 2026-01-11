# sioyek-dict

<!--toc:start-->
- [sioyek-dict](#sioyek-dict)
  - [Features](#features)
  - [Dependencies](#dependencies)
  - [Install](#install)
  - [Build](#build)
  - [Debugging](#debugging)
  - [Sioyek Configuration](#sioyek-configuration)
  - [Usage](#usage)
<!--toc:end-->

Dictionary lookup extension for Sioyek PDF reader with lemmatization support.

## Features

- WordNet dictionary definitions
- Lemmatization via nlprule (e.g., "running" → "run", "went" → "go")
- POS-aware lookups for accurate definitions

## Dependencies

- Rust toolchain
- Python with NLTK (for WordNet download)

## Install

```bash
make install
```

Installs binary to `~/.local/bin/sioyek-dict`.

## Build

```bash
make build
```

First build downloads:
- WordNet to `~/.cache/nltk_data/corpora/wordnet/`
- nlprule tokenizer to `~/.cache/nlprule/`

## Debugging

```bash
cargo run --example=pos_test --release
```

Test CLI directly (uses `echo` to print what would be sent to Sioyek):

```bash
cargo run --release -- /usr/bin/echo "went"
# Output: went: [verb] [go] change location

cargo run --release -- /usr/bin/echo "mice"
# Output: mice: [noun] [mouse] any of numerous small rodents...
```

Check debug log:

```bash
cat ~/.cache/sioyek-dict.log
```

## Sioyek Configuration

Add to `prefs_user.config`:

```
new_command _define_word sioyek-dict "%1" "%{sioyek_path}"
```

Add to `keys_user.config`:

```
_define_word <C-d>
```

## Usage

Select text in Sioyek and press `Ctrl+d` to see the definition in the status bar.
