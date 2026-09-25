import os
from pathlib import Path
from visidata import vd, VisiData

vd.options.clipboard_copy_cmd = 'xclip -selection clipboard'

keys_file = Path('~/.config/visidata/keys.py').expanduser()
if keys_file.exists():
    exec(keys_file.read_text())


LIGHT_THEME = {
    'color_default':      '235 on 230',
    'color_current_row':  '235 on 223',
    'color_current_col':  '235 on 223',
    'color_current_cell': '230 on 130',
    'color_default_hdr':  '235 on 223',
    'color_current_hdr':  '230 on 130',
    'color_key_col':      '24 on 230',
    'color_selected_row': '235 on 187',
    'color_edit_cell':    '235 on 187',
    'color_error':        '124 on 230',
    'color_warning':      '136 on 230',
    'color_menu':         '235 on 223',
    'color_menu_active':  '230 on 130',
    'color_status':       '235 on 223',
    'color_column_sep':   '241',
}


DARK_THEME = {
    'color_default':      '223 on 235',
    'color_current_row':  '223 on 237',
    'color_current_col':  '223 on 237',
    'color_current_cell': '235 on 214',
    'color_default_hdr':  '223 on 239',
    'color_current_hdr':  '235 on 214',
    'color_selected_row': '223 on 239',
    'color_key_col':      '109 on 235',
    'color_edit_cell':    '223 on 239',
    'color_error':        '167 on 235',
    'color_warning':      '214 on 235',
    'color_menu':         '223 on 237',
    'color_menu_active':  '235 on 214',
    'color_status':       '223 on 237',
    'color_column_sep':   '243',
}

_last_theme = None


def update_theme(*args, **kwargs):
    global _last_theme

    is_light = Path('~/.lightmode').expanduser().exists()

    if is_light == _last_theme:
        return

    _last_theme = is_light
    theme = LIGHT_THEME if is_light else DARK_THEME

    for name, value in theme.items():
        setattr(vd.options, name, value)


@VisiData.before
def draw_all(self):
    update_theme()


update_theme()
