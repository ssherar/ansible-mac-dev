# ansible-mac-dev

A YAAP (yet another ansible playbook) for setting up a macbook for development work, loosely derived from the great geerlingguy's work, both from his [mac dev playbook](https://github.com/geerlingguy/mac-dev-playbook) and his [ansible collection for mac](https://github.com/geerlingguy/ansible-collection-mac)

It might fit your needs, but definitely fits mine, so feel free to either use it as-is, derive your own work from it, or fork it and hack away with what you might require for your specific needs. I'm happy to take PRs for fixes when run on your machine or other potential tools that might be good to have but selfishly it's main purpose of this repository is for me, myself and I.

## Requirements
All the requirements can be found by the `pre-install.sh` script that tries to install XCode Developer tools and Ansible inside pipx to try and clean it up from the system's python installation. 

Unfortunately i cannot test on this Mac due to homebrew being already installed and hijacking the systems `python` interpreter for its own (which is a good thing!) and i'm too lazy to test with the MacOS baked in version. Maybe another time or the inevitable reimage that will come at some point

## Config and Tooling
A loose list of major tasks is as follows:

* Homebrew installation with typical casks and formulas
* MacOS Dock modification
* VS Code configuration for extensions and custom config
* Git configuration
* Shell and iTerm configuration

To see the list of tools and configs, have a look at `default.config.yml` to see whats going on

## Manual tasks
Alas with MacOS, there are a couple of post-run steps that need to be done manually. I'm sure they can be automated to a point, but there are diminishing returns for the actions so it's simpler to do it yourself. These are:

1. **1Password authentication for `op` and setting up ssh agent config**

    Make sure you boot up 1Password application and authenticate as normal. Once done, open settings and head to the developers group to set up ssh agent and the `op` bridge. When setting up the SSH agent, let 1Password change your ssh_config for the proxy command. **It knows best over you and shouldn't conflict with the SSH configuration steps**

    Once done, test by authenticating to github via ssh (`ssh -T github.com`) with the key associated in 1Password. As well, test the `op` bridge by signing in using `op signin`. If successfull you'll get an output using `op whoami`

1. **Dock configuration**

    The steps in the `geerlingguy.mac.dock` which kills and waits for the dock *sometimes* works, but if its looking strange just make sure you manually kill the dock via `killall Dock`

1. **Set up the `code` symlink**

    While the Visual Studio task within this playbook doesn't require the `code` symlink to be set up, it might be useful for you. Unfortunately there is no simple way to do it programmatically so booting up in VS Code and heading to the command pallete (`Cmd+Shift+P`) and searching for `Shell Command: install 'code' command in your PATH` will run the oasscript built-in. **Again, it knows better than you to manually add it to your path!**

## Author

Sam Sherar

## Licence
MIT