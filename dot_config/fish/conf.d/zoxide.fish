# zoxide: `z` jumps to frecent directories, `zi` picks one interactively
if status is-interactive; and command -q zoxide
    zoxide init fish | source
end
