# wl2kpi -- Not ready for use!

## Introduction

### This repo contains scripts & notes for AX.25/RMSGW-Linux/paclink-unix/ on a fresh Raspbian image.

#### The script will run the following configurations:
* Core only
	* this includes AX.25 & tools for running a TNC-PI on a Raspberry Pi 2 or 3
* RMS Winlink Gateway for linux
* Paclink-unix in two flavors
	* paclink-unix basic which allows using a movemail e-mail client like mutt
	* paclink-unix imap which allows using any e-mail client that supports. IMAP

Note: These scripts are meant to only be run once and only on a fresh image.

### Installation Scripts

#### Core
Core is required for any other packet apps using a TNC-PI. this option Configures a 
rasberry pi 2 or 3 for using a TNC-PI for either serial /dev/ttyAMA0 or i2c operation.


Regardless of what functionality you want ot install, the first thing to run is install.sh

#### AX.25
AX.25 is required for communication with TNC-pi 
AX.25 tools/apps/library will also be installed. As part of the requirements this
option also configures systemd to start AX.25 at boot time.

#### RMS Gateway
In order to install the linux RMS Gateway you must register with Winlink to get a password
for a gateway.
See rmsgw_install.md for details on installing RMS Gateway functionality.

#### paclink-unix
* Two installation options:
	* basic - installs paclink-unix, mutt & postfix
	* imap - installs the above plus, dovecot imap mailserver & hostapd WiFi access point, and dnsmasq to serve up DNS & DHCP when the RPi 3 is not connected to a network.
	
#### paclink-unix basic

This is a light weight paclink-unix install that gives functionality to use an e-mail client 
on the Raspberry Pi to compose & send winlink messages.

Installs the following:

* paclink-unix to format e-mail
* postfix for the mail transfer agent
* mutt for the mail user agent

#### paclink-unix imap

This installs functionality to use any imap e-mail client & to access paclink-unix from a browser.
It allows using a WiFi device (smart phone, tablet, laptop) to compose a Winlink message & envoke 
paclink-unix to send the message. This is also configured to cough up a dhcp config for your mobil 
device if your RPi 3 is in a car not connected to the Internet.

#### Installs the following:

	* paclink-unix to format e-mail
	* postfix for the mail transfer agent
	* dovecot, imap e-mail server
	* hostapdd to enable a Raspberry Pi 3 to be a virtual access point
	* dnsmasq to allow connecting to the Raspbery Pi when it is not connected to a network
	* nodejs to host the control page for paclink-unix
	* iptables to enable NAT
	
### Special recognition
Thanks goes out to k4gbb and n7nix, their scripts and code provided me with the basics to understanding 
and customizing this set of install scripts for my version of a working rpi with a TNC-PI. Hopefully others
will find this useful as well.
W4CSN

### Web Sources used:
#### Installing Rasbian
* https://www.raspberrypi.org/downloads/raspbian/
* https://www.raspberrypi.org/documentation/installation/installing-images/README.md

#### Configuring pi for tnc-pi
* https://tnc-x.com/TNCPi.htm

#### Installing an configuring ax25 and rms gateway
K4gbb links
* http://packet-radio.net/docs/
* https://packet-radio.net/downloads/

#### Installing and configuring paclink-unix and postfix:
* http://bazaudi.com/plu/doku.php

#### Help with postfix and dovecot imapd:
* https://samhobbs.co.uk/2013/12/raspberry-pi-email-server-part-1-postfix

#### Notes on linbpq:
* http://www.tnc-x.com/InstallingLINBPQ.htm

Winlink clients for linux:
paclink-unix
Pat   http://getpat.io

Winlink clients for windows:
Winlink Express

#### AX.25 source Code
*https://github.com/ve7fet/linuxax25

#### Installation Scripts from n7nix
* https://github.com/nwdigitalradio/n7nix
* https://github.com/nwdigitalradio/rmsgw
* https://github.com/nwdigitalradio/paclink-unix
