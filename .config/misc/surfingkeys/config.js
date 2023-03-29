api.map('u', 'e');
api.mapkey('p', "Open the clipboard's URL in the current tab", function() {
    Front.getContentFromClipboard(function(response) {
        window.location.href = response.data;
    });
});
api.map('P', 'cc');
api.map('H', 'S');
api.map('L', 'D');
api.map('gt', 'R');
api.map('gT', 'E');
api.map('<Alt-g>', '<Ctrl-6>');
api.unmap('gm');
api.unmap('<Ctrl-[>');
api.unmap('<Ctrl-]>');
api.iunmap('<Ctrl-[>');
api.iunmap('<Ctrl-]>');
api.vunmap('<Ctrl-[>');
api.vunmap('<Ctrl-]>');
api.map('<Ctrl-[>', '<Esc>');
api.imap('<Ctrl-[>', '<Esc>');
api.vmap('<Ctrl-[>', '<Esc>');
api.removeSearchAlias('b');
api.removeSearchAlias('e');
api.removeSearchAlias('h');
api.removeSearchAlias('w');
api.addSearchAlias('m', 'maps', 'http://maps.google.com/?q=', 's', 'https://www.google.com/complete/search?client=chrome-omni&gs_ri=chrome-ext&oit=1&cp=1&pgcl=7&q=', function(response) {
        var res = JSON.parse(response.text);
        return res[1];
    });
api.addSearchAlias('w', 'wikipedia', 'https://en.wikipedia.org/wiki/', 's', 'https://en.wikipedia.org/w/api.php?action=opensearch&format=json&formatversion=2&namespace=0&limit=40&search=', function(response) {
        return JSON.parse(response.text)[1];
    });
api.addSearchAlias('h', 'github', 'https://github.com/search?q=', 's');
