# vi mode; ciw, diw, yiw, caw and friends are built in
set -g fish_key_bindings fish_vi_key_bindings
# wait this long (ms) for the second key of a sequence like jk
set -g fish_sequence_key_delay_ms 300

# fish runs this after installing the vi bindings
function fish_user_key_bindings
    bind -M insert -m default jk backward-char repaint-mode
    __surround_bindings
end
