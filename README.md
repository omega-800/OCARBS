# OMEGA's Custom Auto-Rice Bootstrapping Scripts (OCARBS)

## Installation:

On an Arch-based distribution as root, run the following:

```
curl -LO https://raw.githubusercontent.com/omega-800/OCARBS/master/static/ocarbs.sh
sh ocarbs.sh
```

That's it.

## What is OCARBS?

OCARBS is a script that autoinstalls and autoconfigures a fully-functioning
and bloated (but riced) terminal-and-vim-based Arch Linux environment.

OCARBS can be run on a fresh install of Arch or Artix Linux, and provides you
with a fully configured diving-board for work or more customization.

## Why OCARBS
- Fully-featured
    - Multiple desktop environments to have fun playing around with? ✓ check
    - Nix for stable (but also *fresh*) packages, impermanent dev-environments and reproducibility? ✓ check
    - Multiple styling themes, applied to _almost_ every pkg with stylix? ✓ check
- VIM MOTIONS EVERYWHERE
- It has a funny name as well, ngl

## Customization

By default, OCARBS uses the programs and dotfiles in my [my nix-config repo (voidrice) here](https://github.com/kuchteq/wayrice)
as well as system packages [here in progs.csv](static/progs.csv),
but you can easily change this by either modifying the default variables at the
beginning of the script or giving the script one of these options:

- `-r`: custom dotfiles repository (URL)
- `-p`: custom programs list/dependencies (local file or URL)
- `-a`: a custom AUR helper (must be able to install with `-S` unless you
  change the relevant line in the script

### The `progs.csv` list

OCARBS will parse the given programs list and install all given programs. Note
that the programs file must be a three column `.csv`.

The first column is a "tag" that determines how the program is installed, ""
(blank) for the main repository, `A` for via the AUR, `G` if the program is a
git repository that is meant to be `make && sudo make install`ed, `P` if the 
program is meant to be installed through pip and lastly `X` if the program 
shouldn't be installed at all but simply run as a service (as explained below).

The second column is a "tag" that determines if the program is a service and if so, 
how it should be run. "" (blank) for no service, `U` for --user or `S` if 
the program should be run as a "normal" system service..

The third column is the name of the program in the repository, or the link to
the git repository, and the fourth column is a description (should be a verb
phrase) that describes the program. During installation, OCARBS will print out
this information in a grammatical sentence. It also doubles as documentation
for people who read the CSV and want to install my dotfiles manually.

Depending on your own build, you may want to tactically order the programs in
your programs file. OCARBS will install from the top to the bottom.

If you include commas in your program descriptions, be sure to include double
quotes around the whole description to ensure correct parsing.

### The script itself

The script is extensively divided into functions for easier readability and
trouble-shooting. Most everything should be self-explanatory.

The main system-related work is done by the `installationloop` function, 
which iterates through the programs file and determines based on the tag 
of each program, which commands to run to install it. Nix does the heavy 
lifting related to user programs and dotfiles. You can read more about Nix
[here](https://nixos.org/) and about the Nix home-manager [here](https://nix-community.github.io/home-manager/). You can easily add new methods 
of installations and tags as well.

Note that programs from the AUR can only be built by a non-root user. What
OCARBS does to bypass this by default is to temporarily allow the newly created
user to use `sudo` without a password (so the user won't be prompted for a
password multiple times in installation). This is done ad-hocly, but
effectively with the `newperms` function. At the end of installation,
`newperms` removes those settings, giving the user the ability to run only
several basic sudo commands without a password (`shutdown`, `reboot`,
`pacman -Syu`).

