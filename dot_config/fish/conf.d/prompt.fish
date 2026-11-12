# oh-my-posh prompt: ~/.config/oh-my-posh/config.omp.json extends the Kanagawa Wave theme from .chezmoiexternal.toml
if status is-interactive; and command -q oh-my-posh; and test -f ~/.config/oh-my-posh/themes/kanagawa-wave.omp.json
    oh-my-posh init fish --config ~/.config/oh-my-posh/config.omp.json | source
end
