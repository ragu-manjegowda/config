# This is done is zsh
# PS1="\u:\w$ "

##########################################################################################
################                Mac basic ENV exports             ########################
##########################################################################################

# Homebrew Path
export HOMEBREW_PATH="$HOME/Documents/homebrew"
export PATH="$HOMEBREW_PATH/bin:$PATH"
export PATH="$HOMEBREW_PATH/sbin:$PATH"

# Bash-completion
[[ -r "$HOMEBREW_PATH/etc/profile.d/bash_completion.sh" ]]
source "$HOMEBREW_PATH/etc/profile.d/bash_completion.sh"

## Git-completion (zsh already has plugin for git)
# if [ -f ~/.git-completion.bash ]; then
#   . ~/.git-completion.bash
# fi

# # Config alias (done in zsh)
# alias config='git --git-dir=$HOME/.config.git/ --work-tree=$HOME'

# # Tmux alias
# alias tmux='TERM=xterm-256color tmux'

##########################################################################################
################            ENV exports of Packages and libs      ########################
##########################################################################################

# Asciidoc
export XML_CATALOG_FILES="$HOMEBREW_PATH/etc/xml/catalog:$XML_CATALOG_FILES"

# Bison
export PATH="$HOMEBREW_PATH/opt/bison/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/bison/lib:$LDFLAGS"

# DocBook package in XML
export XML_CATALOG_FILES="$HOMEBREW_PATH/etc/xml/catalog:$XML_CATALOG_FILES"

# FFI
export LDFLAGS="-L$HOMEBREW_PATH/opt/libffi/lib:$LDFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/libffi/include:$CPPFLAGS"

# GCC linker warning fix
# ld: warning: text-based stub file /System/Library/Frameworks//Cocoa.framework/Cocoa.tbd
# and library file /System/Library/Frameworks//Cocoa.framework/Cocoa are out of sync.
export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"

# Gettext exports
export PATH="$HOMEBREW_PATH/opt/gettext/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/gettext/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/gettext/include:$CPPFLAGS"

# GNU-getopt
export PATH="$HOMEBREW_PATH/opt/gnu-getopt/bin:$PATH"

# Gnutls
export GUILE_TLS_CERTIFICATE_DIRECTORY="$HOMEBREW_PATH/etc/gnutls"

# Guile
export GUILE_LOAD_PATH="$HOMEBREW_PATH/share/guile/site/3.0"
export GUILE_LOAD_COMPILED_PATH="$HOMEBREW_PATH/lib/guile/3.0/site-ccache"
export GUILE_SYSTEM_EXTENSIONS_PATH="$HOMEBREW_PATH/lib/guile/3.0/extensions"

# ICU4C
export PATH="$HOMEBREW_PATH/opt/icu4c/bin:$PATH"
export PATH="$HOMEBREW_PATH/opt/icu4c/sbin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/icu4c/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/icu4c/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"

# Java
export PATH="$HOMEBREW_PATH/opt/openjdk@11/bin:$PATH"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/openjdk@11/include:$CPPFLAGS"

# Jekyll
export PATH="$HOMEBREW_PATH/lib/ruby/gems/2.6.0/bin/:$PATH"

# LibPcap
export PATH="$PATH:$HOMEBREW_PATH/opt/libpcap/bin"
export LDFLAGS="-L/Users/ragu/Documents/homebrew/opt/libpcap/lib:$LDFLAGS"
export CPPFLAGS="-I/Users/ragu/Documents/homebrew/opt/libpcap/include:$CPPFLAGS"

# Libxml2
export PATH="$HOMEBREW_PATH/opt/libxml2/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/libxml2/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/libxml2/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/libxml2/lib/pkgconfig:$PKG_CONFIG_PATH"

# Ncurses
export PATH="$HOMEBREW_PATH/opt/ncurses/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/ncurses/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/ncurses/include:$CPPFLAGS"

# Openssl
export PATH="$HOMEBREW_PATH/opt/openssl/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/openssl/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/openssl/include:$CPPFLAGS"

# Openssl@1.1
export PATH="$HOMEBREW_PATH/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/openssl@1.1/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/openssl@1.1/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/openssl@1.1/lib/pkgconfig:$PKG_CONFIG_PATH"

# Python
export PYTHONPATH="$HOMEBREW_PATH/bin:$PYTHONPATH"
export PYTHONPATH="$HOMEBREW_PATH/etc:$PYTHONPATH"

# Python 3.8
export PATH="$PATH:$HOMEBREW_PATH/opt/python@3.8/bin"
export LDFLAGS="-L$HOMEBREW_PATH/opt/python@3.8/lib:$LDFLAGS"

# Qt
export PATH="$HOMEBREW_PATH/opt/qt/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/qt/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/qt/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/qt/lib/pkgconfig:$PKG_CONFIG_PATH"

# Qt@5
export PATH="$HOMEBREW_PATH/opt/qt@5/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/qt@5/lib"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/qt@5/include"

# Readline
export LDFLAGS="-L$HOMEBREW_PATH/opt/readline/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/readline/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/readline/lib/pkgconfig:$PKG_CONFIG_PATH"

# Ruby
export PATH="$HOMEBREW_PATH/opt/ruby/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/ruby/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/ruby/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/ruby/lib/pkgconfig:$PKG_CONFIG_PATH"

# Sphinx-doc
export PATH="$HOMEBREW_PATH/opt/sphinx-doc/bin:$PATH"

# Sqlite
export PATH="$HOMEBREW_PATH/opt/sqlite/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/sqlite/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/sqlite/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/sqlite/lib/pkgconfig:$PKG_CONFIG_PATH"

# Tesseract
export TESSDATA_PREFIX="$HOMEBREW_PATH/Cellar/tesseract/4.1.1/share/tessdata"

# Tclap
export CPPFLAGS="-I$HOMEBREW_PATH/opt/tclap/include:$CPPFLAGS"
export PKG_CONFIG_PATH="$HOMEBREW_PATH/opt/tclap/lib/pkgconfig:$PKG_CONFIG_PATH"

# Tcl-tk
export PATH="$HOMEBREW_PATH/opt/tcl-tk/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/tcl-tk/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/tcl-tk/include:$CPPFLAGS"

# Vtk
export PATH="$HOMEBREW_PATH/opt/vtk@8.2/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PATH/opt/vtk@8.2/lib:$LDFLAGS"
export CPPFLAGS="-I$HOMEBREW_PATH/opt/vtk@8.2/include:$CPPFLAGS"

# Zim fix (DYLD_FALLBACK_LIBRARY_PATH)
export DY_PATH="$HOMEBREW_PATH/Cellar/atk/2.36.0/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/cairo/1.16.0_5/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gdk-pixbuf/2.42.2/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gobject-introspection/1.66.1_1/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/gtk+3/3.24.26/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/harfbuzz/2.7.4_1/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/Cellar/pango/1.48.4/lib"
export DY_PATH="$DY_PATH:$HOMEBREW_PATH/lib"

export DYLD_FALLBACK_LIBRARY_PATH="$DYLD_FALLBACK_LIBRARY_PATH:$DY_PATH"
export XDG_DATA_DIRS="$HOMEBREW_PATH/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"

