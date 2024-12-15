"""Solarized colorscheme for ranger.

###############################################################################
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
## References   : @github.com/ranger/colorschemes/solarized.py
###############################################################################
"""

from __future__ import (absolute_import, division, print_function)

from ranger.gui.colorscheme import ColorScheme  # pyright: ignore[reportMissingImports]  # noqa: E501

from ranger.gui.color import (  # pyright: ignore[reportMissingImports]
    default,
    normal, bold, reverse,
    default_colors,
)

from colorschemes.colors import NeoSolarizedColors  # pyright: ignore[reportMissingImports]  # noqa: E501

theme = NeoSolarizedColors.solarized_dark


class NeoSolarized(ColorScheme):
    """Solarized colorscheme for ranger."""

    def use(self, context):
        """Use the Solarized colorscheme."""
        _, _, attr = default_colors

        fg = theme["fg"]
        bg = theme["bg"]

        if context.reset:
            return default_colors

        elif context.in_browser:
            fg = theme["base0"]
            if context.selected:
                attr = reverse
            else:
                attr = normal
            if context.empty or context.error:
                fg = theme["black"]
                bg = theme["red"]
            if context.border:
                fg = default
            if context.media:
                if context.image:
                    fg = theme["yellow"]
                else:
                    fg = theme["orange"]
            if context.container:
                fg = theme["violet"]
            if context.directory:
                fg = theme["blue"]
            elif context.executable and not \
                    any((context.media, context.container,
                         context.fifo, context.socket)):
                fg = theme["green"]
                attr |= bold
            if context.socket:
                fg = theme["yellow"]
                bg = theme["base02"]
                attr |= bold
            if context.fifo:
                fg = theme["yellow"]
                bg = theme["base02"]
                attr |= bold
            if context.device:
                fg = theme["base0"]
                bg = theme["base02"]
                attr |= bold
            if context.link:
                fg = theme["cyan"] if context.good else theme["red"]
                attr |= bold
                if context.bad:
                    bg = theme["base01"]
            if context.tag_marker and not context.selected:
                attr |= bold
                if fg in (theme["red"], theme["magenta"]):
                    fg = theme["white"]
                else:
                    fg = theme["red"]
            if not context.selected and (context.cut or context.copied):
                fg = theme["base03"]
                attr |= bold
            if context.main_column:
                if context.selected:
                    attr |= bold
                if context.marked:
                    attr |= bold
                    bg = theme["base02"]
            if context.badinfo:
                if attr & reverse:
                    bg = theme["magenta"]
                else:
                    fg = theme["magenta"]

            if context.inactive_pane:
                fg = theme["base00"]

        elif context.in_titlebar:
            attr |= bold
            if context.hostname:
                # fg = 16 if context.bad else 255
                if context.bad:
                    bg = theme["orange"]
            elif context.directory:
                fg = theme["blue"]
            elif context.tab:
                fg = theme["cyan"] if context.good else theme["blue"]
                bg = theme["base02"]
            elif context.link:
                fg = theme["cyan"]

        elif context.in_statusbar:
            if context.permissions:
                if context.good:
                    fg = theme["cyan"]
                elif context.bad:
                    fg = theme["red"]
                    # bg = 235
            if context.marked:
                attr |= bold | reverse
                fg = theme["orange"]
                bg = theme["base02"]
            if context.message:
                if context.bad:
                    attr |= bold
                    fg = theme["red"]
                    bg = theme["base02"]
            if context.loaded:
                bg = theme["blue"]

        if context.text:
            if context.highlight:
                attr |= reverse

        if context.in_taskview:
            if context.title:
                fg = theme["cyan"]

            if context.selected:
                attr |= reverse

            if context.loaded:
                if context.selected:
                    fg = theme["blue"]
                else:
                    bg = theme["blue"]

        return fg, bg, attr
