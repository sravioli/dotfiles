source /usr/share/cachyos-fish-config/cachyos-config.fish

# kanagawa themes are installed by fisher (fish_plugins)
if status is-interactive
    fish_config theme choose kanagawa-wave
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
