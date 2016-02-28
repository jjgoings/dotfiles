Dotfiles
========
This repository includes all of my custom dotfiles.  They should be cloned to
your home directory so that the path is `~/dotfiles/`.  The included setup
script creates symlinks from your home directory to the files which are located
in `~/dotfiles/`.

The setup script is smart enough to back up your existing dotfiles into a
`~/dotfiles_old/` directory if you already have any dotfiles of the same name as
the dotfile symlinks being created in your home directory.

I also prefer `zsh` as my shell of choice.  As such, the setup script will also
clone the `oh-my-zsh` repository from my GitHub. It then checks to see if `zsh`
is installed.  If `zsh` is installed, and it is not already configured as the
default shell, the setup script will execute a `chsh -s $(which zsh)`.  This
changes the default shell to zsh, and takes effect as soon as a new zsh is
spawned or on next login.

So, to recap, the install script will:

1. Back up any existing dotfiles in your home directory to `~/dotfiles_old/`
2. Create symlinks to the dotfiles in `~/dotfiles/` in your home directory
3. Clone the `oh-my-zsh` repository from my GitHub (for use with `zsh`)
4. Check to see if `zsh` is installed, if it isn't, try to install it.
5. If zsh is installed, run a `chsh -s` to set it as the default shell.

Installation
------------

``` bash
git clone git://github.com/michaeljsmalley/dotfiles ~/dotfiles
cd ~/dotfiles
./makesymlinks.sh
```

Working with Gaussian DV
-------------

For whatever reason, GDV really only works with C-shell, despite the 
`gdv.profile` file. A workaround to load `gdv` and the `mk` aliases is to use
the `c2z` script in `/dotfiles/`. To use, source it in your `local_zshrc` file 
(should work in bash too), like so
``` bash
. =(~/dotfiles/c2z -l)
```
As long as everything was set up correctly in your old .tcshrc, this should 
set up most of the necessary gaussian specific environmental variables and 
necessay aliases to do development work.

`zshrc` will look for the `local_zshrc` on initialization, so put machine 
specific aliases and environmental variables in there.

It works by converting the sourced c-shell environmental variables, and
converting the syntax to bourne-shell syntax, which then gets sourced when you
login to zsh or bash. I've found it works for ~95% of the things, so some minor
tweaks may be necessary depending on your machine configuration.


