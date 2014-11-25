#!/bin/bash -ex

for p in app-editors/vim-runtime app-editors/vim app-editors/e4r sys-apps/tcp-wrappers 'app-admin/eclectic-python:3' 'dev-lang/python[>3]'; do
    cave uninstall -a -x "$p" --uninstalls-may-break '*/*' || echo dummy
done
cave sync
cave resolve -x1 dev-perl/Locale-gettext
cave resolve -cx installed-slots::installed || sleep 600m
find /var/cache/paludis/distfiles/ -type f -delete

fstrim -v /
