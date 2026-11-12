# dotfiles

[CachyOS](https://cachyos.org) + [KDE](https://kde.org/plasma-desktop/) ❤️ [Kanagawa](https://github.com/kanagawa-community): my [chezmoi](https://chezmoi.io) setup.

It only works on Arch-based systems: the scripts use [pacman](https://wiki.archlinux.org/title/Pacman) and [yay](https://github.com/Jguer/yay).

## What's in it

- **Shell:** [fish](https://fishshell.com) with vi mode, [oh-my-posh](https://ohmyposh.dev), [zoxide](https://github.com/ajeetdsouza/zoxide) and [yazi](https://yazi-rs.github.io)
- **Git:** git config, [delta](https://github.com/dandavison/delta), [gitui](https://github.com/gitui-org/gitui) and [GitAlias](https://github.com/GitAlias/gitalias)
- **Desktop:** [Plasma](https://kde.org/plasma-desktop/) with the [Kanagawa Wave theme](https://github.com/kanagawa-community/kde), [icons](https://github.com/kanagawa-community/icons), [cursors](https://github.com/kanagawa-community/cursors) and a profile picture
- **Login:** [SDDM](https://github.com/sddm/sddm) with [Silent](https://github.com/uiriansan/SilentSDDM) and the [Kanagawa presets](https://github.com/kanagawa-community/silent-sddm)
- **Apps:** [Spotify](https://www.spotify.com) ([Spicetify](https://spicetify.app)), [Zen](https://zen-browser.app) ([Sine](https://github.com/CosmoCreeper/Sine) mods), [btop](https://github.com/aristocratos/btop) and [bat](https://github.com/sharkdp/bat)
- **Packages:** repos, AUR and CachyOS gaming ([Steam](https://store.steampowered.com), [Lutris](https://lutris.net), [Heroic](https://heroicgameslauncher.com), [Proton](https://github.com/ValveSoftware/Proton))

[Neovim](https://github.com/sravioli/nvim) and [WezTerm](https://github.com/sravioli/wezterm) have their own repos. The first apply clones them into `~/.config`, then chezmoi leaves them alone.

## Install

Plasma writes its settings back to disk on logout, which undoes part of an apply run inside a session (the panel layout especially). So run it from a text console: log out, press Ctrl+Alt+F3, log in and run

```sh
sudo pacman -S chezmoi
chezmoi init --apply sravioli/dotfiles
```

It asks for your sudo password a few times and takes a while, mostly AUR builds. A package that fails to build doesn't stop the apply; the failures are listed at the end and again after every `chezmoi apply` until they're installed. Reboot from the console afterwards to get the new login screen.

<details>
<summary>If Ctrl+Alt+F3 doesn't switch to the console</summary>

1. In Konsole, run `sudo chvt 3`.
2. Log in there.
3. Stop the Plasma session, which would otherwise overwrite the apply when it ends: `sudo systemctl stop display-manager`.
4. Run the install commands above.

</details>

## What the apply does

The scripts in `.chezmoiscripts/` handle what lives outside the home folder:

- rank the pacman mirrors, like "Rank mirrors" in [CachyOS Hello](https://wiki.cachyos.org/features/cachyos_hello/)
- install the packages
- install oh-my-posh with its upstream installer, the first time only
- make SDDM the login screen (recent CachyOS ISOs default to Plasma Login Manager) and theme it
- patch [Spotify](https://www.spotify.com) with [Spicetify](https://spicetify.app) (Text theme, Marketplace), without Spotify having been opened first
- install [Sine](https://github.com/CosmoCreeper/Sine) in [Zen](https://zen-browser.app) with the mods from `zen/sine-mods/`; Sine keeps them updated afterwards
- apply the Kanagawa Wave global theme once, if a Plasma session is running (Plasma keeps its settings in `~/.config/kdedefaults`, which chezmoi doesn't track)
- set the profile picture from `~/.face`

Themes for fish, delta, bat, btop, gitui and oh-my-posh come from [kanagawa-community](https://github.com/kanagawa-community) via `.chezmoiexternal.toml`, pinned to a tag or commit. Change the pin there to update.

## Customising

- Login screen preset (`kanagawa-dragon`, `kanagawa-lotus`): `preset=` in `.chezmoiscripts/run_onchange_after_set-sddm-theme.sh.tmpl`
- Prompt theme or options: `extends` and `var` in `dot_config/oh-my-posh/config.omp.json` (variants `wave`, `dragon`, `lotus`, `dynamic`)
- gitui theme: the `theme.ron` link in `dot_config/gitui/`

The fish config in `dot_config/fish/` is split by job:

- `conf.d/aliases.fish`: aliases
- `conf.d/path.fish`: PATH
- `conf.d/prompt.fish`: the prompt
- `conf.d/vi.fish`: vi mode; `jk` leaves insert mode, `ctrl-r` and `?` search history
- `conf.d/surround.fish`: [nvim-surround](https://github.com/kylechui/nvim-surround) keys: `ds"`, `cs"'`, `ysiw)`, `yss(`, visual `S(`; any punctuation works, plus tags with `t` and calls with `f`
- `functions/`: one file per function, autoloaded; `y` is the [yazi](https://yazi-rs.github.io) wrapper that changes to the directory you quit in

`system-upgrade` updates packages, plugins, oh-my-posh and Spotify's patch in one go.

## Keeping the repo in sync

After changing settings in KDE System Settings, copy them back:

```sh
chezmoi re-add
```

To save Zen mods and settings you changed in Sine:

```sh
rsync -a --delete --exclude '*.zip' ~/.config/zen/*.Default\ \(release\)/chrome/sine-mods/ ~/.local/share/chezmoi/zen/sine-mods/
~/.local/share/chezmoi/zen/export-prefs.sh
```

The settings are applied on the next `chezmoi apply`, while Zen is closed. API keys for Tidy Downloads' AI renaming are never saved.

## Releasing

From a clean `main`, [cocogitto](https://docs.cocogitto.io) works out the version from the commit messages, tags the latest commit and pushes `main` and the tag:

```sh
cog bump --auto   # the first release: cog bump --version 1.0.0
```

The tag starts the `release` workflow, which publishes a GitHub release with the `cog changelog` notes.

## Testing

Install what the tests need (chezmoi, podman for the container, QEMU and UEFI firmware for the VM):

```sh
sudo pacman -S --needed chezmoi podman qemu-desktop edk2-ovmf
```

- `test/check.sh` (seconds): renders and syntax-checks every script, then applies into a temporary folder. Runs in [GitHub Actions](https://docs.github.com/actions) on every push and as my git pre-commit hook.
- `test/container.sh` (slow): full apply, packages included, as a new user in a CachyOS [podman](https://podman.io) container. No desktop.
- `test/vm.sh install`, then `test/vm.sh` (slowest): boots CachyOS in [QEMU](https://www.qemu.org) to check the desktop and login screen. `install` makes a base disk from the latest ISO; each run then boots a throwaway copy, so every run is a fresh install. Images go in `~/vms` (`VM_DIR` changes that).

The VM sees the repo as the 9p share `dotfiles`. Mount it and apply from a text console, like on a real machine:

```sh
sudo mount -t 9p -o trans=virtio,ro dotfiles /mnt
chezmoi init --apply --source /mnt
```
