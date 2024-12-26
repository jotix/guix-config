# Installing the system

Now we can start the system installation!

First we need to set up the Guix build daemon
to target the new system partition by running
this command:

	herd start cow-store /mnt

We also want to save the channel configuration
that was used to produce the installer image onto
our new machine, so we will copy it over now:

	cp /etc/channels.scm /mnt/etc/
	chmod +w /mnt/etc/channels.scm

The following command will install your system configuration
using the included channels.scm file so that you get both
the main Guix channel and the Nonguix channel which contains
the full Linux kernel:

	sudo guix archive --authorize < signing-key.pub
	guix time-machine -C ./channels.scm -- system init ./config.scm /mnt --substitute-urls='https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org'

This command uses the channel defined in clannels.scm and the substitutes for nonguix alternatively run the script wich contains the last command

    ./install.sh
