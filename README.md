
INSTRUCTIONS

1) Generate a key pair or use a alredy existing key pair
	1.1) Example: ssh-keygen -t rsa 4096
2) Always apply diffconfig with the following steps.
	2.1) cp diffconfig <OpenWRT root directory>/.config
	2.2) On OpenWRT root directory: make defconfig
3) Run make menuconfig on OpenWRT root directory and
	3.1) Select target device
	3.2) Select flashman-plugin package on Utilities
	3.3) *IMPORTANT* Configure key pair path generated on step 1.
	3.4) *IMPORTANT* Configure public key file name generated on step 1.
	3.5) Configure FlashMan IP address or FQDN
	3.6) Change SSID, password and release ID if desired

COPYRIGHT

Copyright (C) 2017-2017 LAND/COPPE/UFRJ

LICENSE

This is free software, licensed under the GNU General Public License v2.
The formal terms of the GPL can be found at http://www.fsf.org/licenses/