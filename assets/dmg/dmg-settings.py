# dmgbuild settings for the Nivlet install window.
# scripts/make-dmg.py passes -D app=<Nivlet.app> -D background=<background.tiff>.
# The background (660 x 400 pt, 1x and 2x) is rendered from background.svg; icon
# centres below must match the arrow drawn in it.
import os.path

application = defines['app']  # noqa: F821  (provided by dmgbuild)
appname = os.path.basename(application)

format = 'UDZO'
filesystem = 'HFS+'
files = [application]
symlinks = {'Applications': '/Applications'}
# Do not set hide_extensions: it writes Finder info onto the app bundle and
# breaks `codesign --verify --strict`.

background = defines['background']  # noqa: F821
window_rect = ((200, 120), (660, 400))
default_view = 'icon-view'
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
arrange_by = None
icon_size = 128
text_size = 13
label_pos = 'bottom'
icon_locations = {appname: (180, 190), 'Applications': (480, 190)}
