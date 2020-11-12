# MIDI CONFIGFS

Simple and versatile script to set up a MIDI USB device in a Raspberry Pi 4
or Orange Pi or any Linux device with UDC, which is a way to say modern kernel
and USB guest capabilities.

The steps are not difficult at all, but documentation was sparse. I hope this
script helps to use the USB MIDI capabilities of Linux Gadgets more.

# Usage

Check the `midiconfigfs.sh` for options to add to `/etc/default/midiconfigfs`
or use `./midiconfigfs.sh --help`.

Normally you may need something like:

```sh
./midiconfigfs.sh --name MYNAME --in-ports 3 --out-ports 3
```

and remove it with

```sh
./midiconfigfs.sh --name MYNAME --remove
```

# Orange PI Zero

I had some problems with rmmod g_serial.

- Added `blacklist g_serial` to `/etc/modprobe.d/blacklist`
- Created a `/etc/default/midiconfigfs` with my default values
- Added my script to be loaded at `/etc/rc.local`

# Bugs, suggestions...

Please open a ticket on GitHub.
