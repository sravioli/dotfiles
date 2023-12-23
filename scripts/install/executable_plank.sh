#!/bin/bash -e
# install kanagawa plank theme

## LOAD LIBRARY  ===============================================================
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

## INSTALL PLANK THEME =========================================================
info "INSTALLING PLANK THEME"

install_pkg "plank"

rm_dir "/tmp/Kanagawa-GKT-Theme/" && ok "ready to clone"

info "cloning..." &&
  git clone https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme.git /tmp/Kanagawa-GKT-Theme &>/dev/null

cp --recursive /tmp/Kanagawa-GKT-Theme/extra/plank/* "${XDG_DATA_HOME}/plank/themes" &&
  ok "installed Theme for plank. Please apply it"

if is_executable "plank"; then
  info "opening plank settings..." && plank --preferences
else
  error "could not open plank. Check if it's installed"
fi

confirm "make plank autostart on launch?" && (
  mk_dir ~/.config/autostart/
  touch ~/.config/autostart/plank.desktop
  cat <<\EOF >~/.config/autostart/plank.desktop
[Desktop Entry]
Name=Plank
GenericName=Dock
Comment[am]=በጣም ቀላል
Comment[ar]=بسيط بغباء.
Comment[bg]=Пределно прост.
Comment[bs]=Glupavo jednostavan.
Comment[ca]=Estúpidament simple.
Comment[cs]=Stupidně jednoduchý.
Comment[da]=Super simpel.
Comment[de]=Lächerlich einfach.
Comment[el]=Βλακωδώς απλό.
Comment[en_AU]=Stupidly simple.
Comment[en_CA]=Stupidly simple.
Comment[en_GB]=Stupidly simple.
Comment[eo]=Stulte simple.
Comment[es]=Estúpidamente simple.
Comment[et]=Hämmastavalt lihtne.
Comment[eu]=Erraza baino errazagoa.
Comment[fi]=Todella yksinkertainen.
Comment[fr]=Stupidement simple.
Comment[ga]=Simplíocht shimplí.
Comment[gd]=Cho furasta 's a ghabhas.
Comment[gl]=Estupidamente simple.
Comment[he]=טפשי עד כמה שזה פשוט
Comment[hr]=Neviđeno jednostavan
Comment[hu]=Nagyszerűen egyszerű.
Comment[id]=Begitu sederhana.
Comment[it]=Stupidamente semplice.
Comment[ja]=超シンプル
Comment[ka]=ძალიან მარტივი აი ძალიან
Comment[ko]=어처구니없으리 만치 단순한.
Comment[lt]=Kvailai paprastas.
Comment[lv]=Muļķīgi vienkārši.
Comment[ml]=അനായാസം.
Comment[ms]=Ringkas la sangat.
Comment[nb]=Uforstandig enkelt.
Comment[ne]=एकदमै सरल
Comment[nl]=Belachelijk eenvoudig.
Comment[nn]=Idiotsikkert
Comment[pl]=Idiotycznie prosty.
Comment[pt]=Estupidamente simples.
Comment[pt_BR]=Estupidamente simples.
Comment[ro]=Stupid de simplu.
Comment[ru]=До безумного прост.
Comment[sk]=Primitívne jednoduchý.
Comment[sl]=Bedasto preprost.
Comment[sma]=dle dan aelhkies.
Comment[sr]=Шашаво једноставно.
Comment[sr@latin]=Glupavo jenostavan.
Comment[sv]=Galet enkelt.
Comment[ta]=மிகவும் எளிது
Comment[te]=చాలా సరళమైనది.
Comment[th]=ง่ายเหี้ยๆ
Comment[tr]=Son derece basit.
Comment[uk]=Просто легкий.
Comment[uz]=Ahmoqona darajada sodda.
Comment[vi]=Cực kì đơn giản.
Comment[zh_CN]=简单得无语。
Comment[zh_TW]=極簡。
Comment=Stupidly simple.
Categories=Utility;
Type=Application
Exec=plank
Icon=plank
Terminal=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Hidden=false
Name[en_US]=Plank
Comment[en_US]=Stupidly simple.
X-GNOME-Autostart-Delay=0
EOF
)

ok "DONE INSTALLING PLANK THEME"
