// ----------------------------------------------------------------------------
// -- Author       : Ragu Manjegowda
// -- Github       : @ragu-manjegowda
// ----------------------------------------------------------------------------

// Custom themes, neosolarized-(dark|light)
solarizedDark = `
    .sk_theme {
        font-family: Hack Nerd Font Mono;
        font-size: 12pt;
        background: #002b36;
        color: #268bd2;
    }
    .sk_theme tbody {
        color: #073642;
    }
    .sk_theme input {
        color: #839496;
    }
    .sk_theme .url {
        color: #859900;
    }
    .sk_theme .annotation {
        color: #d33682;
    }
    .sk_theme .omnibar_highlight {
        color: #002b36;
        background: #b58900;
    }
    .sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
        background: #073642;
    }
    .sk_theme #sk_omnibarSearchResult ul li.focused {
        color: #fdf6e3;
        background: #586e75;
    }
    .sk_theme #sk_omnibarSearchResult .omnibar_folder {
        color: #cb4b16;
    }
`

solarizedLight = `
    .sk_theme {
        font-family: Hack Nerd Font Mono;
        font-size: 12pt;
        background: #fdf6e3;
        color: #268bd2;
    }
    .sk_theme tbody {
        color: #eee8d5;
    }
    .sk_theme input {
        color: #657b83;
    }
    .sk_theme .url {
        color: #859900;
    }
    .sk_theme .annotation {
        color: #d33682;
    }
    .sk_theme .omnibar_highlight {
        color: #fdf6e3;
        background: #b58900;
    }
    .sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
        background: #eee8d5;
    }
    .sk_theme #sk_omnibarSearchResult ul li.focused {
        color: #002b36;
        background: #93a1a1;
    }
    .sk_theme #sk_omnibarSearchResult .omnibar_folder {
        color: #cb4b16;
    }
`

const isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches

if (isDarkMode) {
    settings.theme = `${solarizedDark}`
} else {
    settings.theme = `${solarizedLight}`
}

settings.defaultSearchEngine = 'd'

api.map('u', 'e')

api.mapkey('p', "Open the clipboard's URL in the current tab", () => {
    Front.getContentFromClipboard((response) => {
        window.location.href = response.data
    })
})

api.map('P', 'cc')
api.map('H', 'S')
api.map('L', 'D')
api.map('gt', 'R')
api.map('gT', 'E')
api.map('<Alt-g>', '<Ctrl-6>')
api.unmap('gm')
api.unmap('<Ctrl-[>')
api.unmap('<Ctrl-]>')
api.iunmap('<Ctrl-[>')
api.iunmap('<Ctrl-]>')
api.vunmap('<Ctrl-[>')
api.vunmap('<Ctrl-]>')
api.map('<Ctrl-[>', '<Esc>')
api.imap('<Ctrl-[>', '<Esc>')
api.vmap('<Ctrl-[>', '<Esc>')
api.unmap('<Ctrl-/>')
api.iunmap('<Ctrl-/>')
api.vunmap('<Ctrl-/>')
api.map('<Ctrl-/>', '<Esc>')
api.imap('<Ctrl-/>', '<Esc>')
api.vmap('<Ctrl-/>', '<Esc>')
api.removeSearchAlias('b')
api.removeSearchAlias('e')
api.removeSearchAlias('h')
api.removeSearchAlias('w')
api.addSearchAlias('h', 'github', 'https://github.com/search?q=', 's')
api.addSearchAlias('m', 'maps', 'http://maps.google.com/?q=', 's')
api.addSearchAlias(
    'w',
    'wikipedia',
    'https://en.wikipedia.org/wiki/',
    's',
    'https://en.wikipedia.org/w/api.php?action=opensearch&format=json&formatversion=2&namespace=0&limit=40&search=',
    (response) => JSON.parse(response.text)[1]
)
