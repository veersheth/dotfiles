# your dotfiles

reference video: https://www.youtube.com/watch?v=y6XCebnB9gs

1. clone repo
`git clone https://github.com/veersheth/dotfiles`

2. install stow
`sudo dnf install stow`

3. apply links
`stow dotfiles`


---

to create a new package:
- mkdir `packagename`
- move relative path from $HOME to the `packagename` folder

for example for neovim:

```bash
cd dotfiles
mkdir nvim
mkdir nvim/.config
mv ~/.config nvim/config
```
