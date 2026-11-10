# oh-my-posh prompt; the theme file comes from the installer's cache
if status is-interactive; and command -q oh-my-posh; and test -f ~/.cache/oh-my-posh/themes/amro.omp.json
    oh-my-posh init fish --config ~/.cache/oh-my-posh/themes/amro.omp.json | source
end
