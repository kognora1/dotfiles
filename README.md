# dotfiles

my personal setup on fedora minimal + hyprland.

## stack

| thing | what |
|---|---|
| os | fedora minimal |
| wm | hyprland |
| bar | waybar |
| terminal | foot |
| shell | zsh |
| launcher | fuzzel |
| editor | neovim |
| notifications | mako |
| theme | catppuccin latte mauve |
| icons | papirus-light |
| cursor | bibata modern ice |
| fonts | jetbrains mono nerd font |

## structure

```
dotfiles/
├── config/     → ~/.config/
├── local/bin/  → ~/.local/bin/
└── home/       → ~/
```

## restore

copy the repo to your machine, then run:

```bash
bash restore.sh
```

requires the hdd mounted at `/mnt/files` with the full backup including fonts, themes and browser profiles.
