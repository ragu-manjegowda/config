PS1="\u:\w$ "

# Homebrew Path
export HOMEBREW_PATH="$HOME/Documents/homebrew"
export PATH="$HOMEBREW_PATH/bin:$PATH"

# Bash-completion
[[ -r "$HOMEBREW_PATH/etc/profile.d/bash_completion.sh" ]]
source "$HOMEBREW_PATH/etc/profile.d/bash_completion.sh"

# Git-completion
if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

# Gettext exports
export PATH="$HOMEBREW_PATH/opt/gettext/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/gettext/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/gettext/include:$CPPFLAGS"

# Openssl
export PATH="$HOMEBREW_PATH/opt/openssl/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/openssl/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/openssl/include:$CPPFLAGS"

# Readline
export LDFLAGS="-L$HOMEBREW_PATH/opt/readline/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/readline/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# Sqlite
export PATH="$HOMEBREW_PATH/opt/sqlite/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/sqlite/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/sqlite/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/sqlite/lib/pkgconfig:$PKG_CONFIG_PATH"

# FFI
export LDFLAGS="-L$HOMEBREW_PATH/opt/libffi/lib:$LDFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"

# ICU4C
export PATH="$HOMEBREW_PATH/opt/icu4c/bin:$PATH"
export PATH="$HOMEBREW_PATH/opt/icu4c/sbin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/icu4c/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/icu4c/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"

# Python
export PYTHONPATH="$HOMEBREW_PATH/bin:$PYTHONPATH"
export PYTHONPATH="$HOMEBREW_PATH/etc:$PYTHONPATH"

# Openssl@1.1
export PATH="$HOMEBREW_PATH/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/openssl@1.1/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/openssl@1.1/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/openssl@1.1/lib/pkgconfig:$PKG_CONFIG_PATH"

# Readline
export LDFLAGS="-L$HOMEBREW_PATH/opt/readline/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/readline/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# Ruby
export PATH="$HOMEBREW_PATH/opt/ruby/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/ruby/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/ruby/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/ruby/lib/pkgconfig:$PKG_CONFIG_PATH"

# Jekyll
export PATH="$HOMEBREW_PATH/lib/ruby/gems/2.6.0/bin/:$PATH"

# Libxml2
export PATH="$HOMEBREW_PATH/opt/libxml2/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/libxml2/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/libxml2/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/libxml2/lib/pkgconfig:$PKG_CONFIG_PATH"

# Qt
export PATH="$HOMEBREW_PATH/opt/qt/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/qt/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/qt/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/qt/lib/pkgconfig:$PKG_CONFIG_PATH"

# DocBook package in XML
export XML_CATALOG_FILES="$HOMEBREW_PATH/etc/xml/catalog:$XML_CATALOG_FILES"

# Tclap
export CPPFLAGS="-I$HOMEBREW_PATH/opt/tclap/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/tclap/lib/pkgconfig:$PKG_CONFIG_PATH"


# Zim fix (DYLD_FALLBACK_LIBRARY_PATH)
export DY_PATH="$HOMEBREW_PATH/Cellar/pango/1.44.7/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gdk-pixbuf/2.40.0/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gtk+3/3.24.18/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/atk/2.36.0/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gdk-pixbuf/2.40.0_1/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gtk+3/3.24.18_1/lib"

export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH:$DY_PATH"
export XDG_DATA_DIRS="$HOMEBREW_PATH/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"

# Bison
export PATH="$HOMEBREW_PATH/opt/bison/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/bison/lib:$LDFLAGS"

# Ncurses
export PATH="$HOMEBREW_PATH/opt/ncurses/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/ncurses/lib"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/ncurses/include"

# GCC linker warning fix
# ld: warning: text-based stub file /System/Library/Frameworks//Cocoa.framework/Cocoa.tbd
# and library file /System/Library/Frameworks//Cocoa.framework/Cocoa are out of sync.
export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"

# Python 3.8
export PATH="$PATH:/Users/ragu/Documents/homebrew/opt/python@3.8/bin"
export LDFLAGS="-L/Users/ragu/Documents/homebrew/opt/python@3.8/lib"

# Config alias
alias config='git --git-dir=$HOME/.config.git/ --work-tree=$HOME'
