"""Solarized color definition for ranger."""

###############################################################################
# Author       : Ragu Manjegowda
# Github       : @ragu-manjegowda
# Reference    : https://ethanschoonover.com/solarized
###############################################################################


class NeoSolarizedColors:
    """Solarized colorscheme for ranger."""

    solarized_dark = {
        "base03": 8,  # bright black
        "base02": 0,  # black
        "base01": 10,  # bright green
        "base00": 11,  # bright yellow
        "base0": 12,  # bright blue
        "base1": 14,  # bright cyan
        "base2": 7,  # white
        "base3": 15,  # bright white
        "yellow": 3,
        "orange": 9,
        "red": 1,
        "magenta": 5,
        "violet": 13,
        "blue": 4,
        "cyan": 6,
        "green": 2,
        "black": 0,  # base02
        "white": 7,  # base2
        "bg": 8,  # bright black
        "fg": 12  # bright blue
    }

    solarized_light = solarized_dark.copy()

    solarized_light.update({
        "base03": solarized_dark["base3"],
        "base02": solarized_dark["base2"],
        "base01": solarized_dark["base1"],
        "base00": solarized_dark["base0"],
        "base0": solarized_dark["base00"],
        "base1": solarized_dark["base01"],
        "base2": solarized_dark["base02"],
        "base3": solarized_dark["base03"],

        "bg": solarized_dark["base3"],  # bright white
        "fg": solarized_dark["base01"]  # bright green
    })
