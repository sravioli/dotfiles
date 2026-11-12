# dotfiles

My [chezmoi](https://chezmoi.io) setup for a CachyOS laptop running KDE Plasma. It covers the shell, git, the desktop and the login screen, and installs the packages they depend on. Everything uses the Kanagawa colour scheme.

It only works on Arch-based systems: the setup scripts use pacman and yay.

## Install

Plasma keeps its settings in memory and writes them back to disk when you log out, so an apply run from inside a Plasma session gets partly undone, the panel layout especially. Run it from a text console instead. On a fresh CachyOS install, log out, press Ctrl+Alt+F3, log in there and run:

```sh
sudo pacman -S chezmoi
chezmoi init --apply sravioli/dotfiles
```

If Ctrl+Alt+F3 doesn't switch to the console, use `chvt` instead:

1. Log in to Plasma as usual and open Konsole.
2. Switch to a text login:

   ```sh
   sudo chvt 3
   ```

3. Log in there with your username and password.
4. Close the Plasma session you left open, which would otherwise write its settings over the apply when it ends:

   ```sh
   sudo systemctl stop display-manager
   ```

5. Run the install commands above.

The apply asks for your sudo password a few times and takes a while, mostly because of the AUR builds. When it finishes, reboot from the same console to get the new login screen:

```sh
systemctl reboot
```

If an AUR package fails to build, the apply carries on and lists the failures at the end. The list comes back after every `chezmoi apply` until those packages are installed.

## What the apply does

Besides copying the dotfiles, the scripts in `.chezmoiscripts/` handle what lives outside the home folder:

- rank the pacman mirrors, the same as the "Rank mirrors" button in CachyOS Hello
- install packages from the repos and the AUR, including CachyOS's gaming packages (Steam, Lutris, Heroic, Proton)
- install the Layan GTK theme from a pinned upstream commit
- install the Kanagawa themes for fish, delta and bat from [kanagawa-community](https://github.com/kanagawa-community)
- install [oh-my-posh](https://ohmyposh.dev) with its upstream installer, the first time only, and use its `amro` theme as the fish prompt
- make SDDM the login screen (recent CachyOS ISOs default to Plasma Login Manager) and theme it with [Silent](https://github.com/uiriansan/SilentSDDM) and a Kanagawa preset
- theme Spotify with [Spicetify](https://spicetify.app): the Text theme's Kanagawa scheme and Marketplace, without having to open Spotify first
- install [Sine](https://github.com/CosmoCreeper/Sine) in Zen with the mods from `zen/sine-mods/`; Sine keeps them updated after that
- apply the Kanagawa Wave global theme once, if a Plasma session is running (Plasma stores its settings in `~/.config/kdedefaults`, which chezmoi doesn't track)
- set the profile picture from `~/.face`

My [Neovim](https://github.com/sravioli/nvim) and [WezTerm](https://github.com/sravioli/wezterm) configs have their own repos. The first apply clones them into `~/.config/nvim` and `~/.config/wezterm`, and after that chezmoi leaves them alone.

## Customising

To change the login screen preset, edit `preset=` in `.chezmoiscripts/run_onchange_after_set-sddm-theme.sh.tmpl`. The presets are `kanagawa-dragon` and `kanagawa-lotus`, both in `sddm/configs/`.

To change the fish prompt, edit the `--config` path in `dot_config/fish/conf.d/prompt.fish`. The built-in themes are in `~/.cache/oh-my-posh/themes/`, and `system-upgrade` keeps oh-my-posh up to date.

Shell settings are split by job under `dot_config/fish/`: `conf.d/aliases.fish` for aliases, `conf.d/path.fish` for PATH, `conf.d/prompt.fish` for the prompt, `conf.d/vi.fish` for vi mode (`jk` leaves insert mode), `conf.d/surround.fish` for nvim-surround's keys (`ds"`, `cs"'`, `ysiw)`, `yss(`, visual `S(`; any punctuation works, plus tags with `t` and calls with `f`), and one file per function in `functions/`, which fish autoloads.

To save Zen mods you've added or changed in Sine, copy them and their settings back into the repo:

```sh
rsync -a --delete --exclude '*.zip' ~/.config/zen/*.Default\ \(release\)/chrome/sine-mods/ ~/.local/share/chezmoi/zen/sine-mods/
~/.local/share/chezmoi/zen/export-prefs.sh
```

The settings are applied on the next `chezmoi apply`, while Zen is closed. API keys for Tidy Downloads' AI renaming are never saved.

The delta and bat themes are pinned in `.chezmoiexternal.toml`. Change the tag or commit there to update them.

After changing settings through KDE System Settings, copy the new files back into the repo:

```sh
chezmoi re-add
```

## Testing

The tests go from a few seconds to a full install.

Install what the tests need (chezmoi, podman for the container, QEMU and UEFI firmware for the VM):

```sh
sudo pacman -S --needed chezmoi podman qemu-desktop edk2-ovmf
```

### Quick check

Renders and syntax-checks every script, then applies the dotfiles into a temporary folder. GitHub Actions runs it on every push, and I run it as a git pre-commit hook too.

```sh
test/check.sh
```

### Container

Runs a full apply, package installs included, as a new user in a CachyOS podman container. Anything that needs a running desktop is out of its reach.

```sh
test/container.sh
```

### Virtual machine

Boots CachyOS in QEMU for checking the desktop and the login screen. The disk images go in `~/vms` (set `VM_DIR` to change that).

The first time, download the latest ISO and install CachyOS onto a base disk:

```sh
test/vm.sh install
```

From then on, each run boots a throwaway copy of that disk, so every run is a fresh install:

```sh
test/vm.sh
```

The VM sees the repo as the 9p share `dotfiles`. Mount it and apply from a text console, the same way as on a real machine:

```sh
sudo mount -t 9p -o trans=virtio,ro dotfiles /mnt
chezmoi init --apply --source /mnt
```
