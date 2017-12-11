#!/bin/bash
# script by Scott Newton ( W4CSN )
# updated November-22-2017
# for Rpi3
# Copy this script file and execute as root.
# It will Download and Install paclink-unix, postfix
# It also assumes that you have already ran the Instax25.new script by k4gbb

# Error Checking
set -u # Exit if there are uninitialized variables.
set -e # Exit if any statement returns a non-true value.

#Constants
wd=$(pwd)
uid=$(id -u)
INST_UID=$USER
PACLINK=https://github.com/nwdigitalradio/paclink-unix


# Color Codes
Reset='\e[0m'
Red='\e[31m'
Green='\e[30;42m'  # Black/Green
Yellow='\e[33m'
YelRed='\e[31;43m' # Red/Yellow
Blue='\e[34m'
White='\e[37m'
BluW='\e[37;44m'   # White/Blue


function Chk_Root
{
# Check for Root
if [ ! uid=0 ]; then
 echo "You must be root User to perform installation!"
 echo "Attempting to change user to root..."
 sudo su || {echo "SU to root Failed! Exiting..."; exit 1}
fi
}

function Install_Tools
{
#Update Package list & Install Build resources
echo -e "${Green} Updating the Package List               ${Reset}"
echo -e "\t${YelRed} This may take a while ${Reset}"
apt-get update > /dev/null
echo "  *"
apt-get install build-essential autoconf automake libtool -y -q
apt-get install postfix libdb-dev libglib2.0-0 zlib1g-dev libncurses5-dev libdb5.3-dev libgmime-2.6-dev -y -q
apt-get install dovecot-common dovecot-imapd telnet -y -q
echo "  *"
}

function Download_paclink
{
# Get current source code for paclink-unix
cd /usr/local/src
if [ ! -d /usr/local/src/paclink-unix ]; then
  echo -e "${Green} Downloading paclink-unix source ${Reset}"
  git clone $PACLINK
else
  echo -e "${Green} updating local paclink-unix source ${Reset}"
  git pull $PACLINK
fi
}

function Compile_paclink
{
# Compile paclink-unix
cd /usr/local/src/paclink-unix
automakever=$(ls -d /usr/share/automake*) # Determine automake version
cp $automakever/missing . # copy missing template to paclink-unix source dir
if [ ! -e README ]; then # autogen expects a README file, but may not be provided by paclink-unix
  touch README
fi  
./autogen.sh --enable-postfix
if [ ! -e Makefile.in ]; then
  automake --add-missing
  ./configure --enable-postfix
fi
make > paclink.txt
if [ $? -ne 0 ]
   then
 echo -e "${BluW}$Red} \tCompile error${White} - check paclink.txt File \t${Reset}"
 exit 1
   else 
 rm paclink.txt
fi
make install
echo -e "${BluW}paclink-unix Installed \t${Reset}"
}

function Configure_Groups
{
# Configure groups
usermod -a -G postdrop $INST_UID
usermod -a -G mail $INST_UID
usermod -a -G adm $INST_UID
cd /usr/local/var/
chown -R $INST_UID:mail wl2k
}

echo -e "${Red} Edit paclink-unix config file in /usr/local/etc/wl2k.conf ${Reset}"
echo -e "${Red} Uncommment any lines that you edit. ${Reset}"
echo -e "Set mycall to your callsign & use UPPERCASE"
echo -e "Set timeout to 190"
echo -e "Set email to " $INST_UID "@localhost"
echo -e "Set wl2k-password"
echo -e "Set ax25port to the portname in /etc/ax25/axports"

function Configure_postfix
{
# Configure postfix

cd /etc/postfix
$CONFIG_FILE=transport
ChkFile_Exist $CONFIG_FILE

# Create postfix transport file using file descriptor (fd) 3
exec 3<> trasnport
echo "#" >&3
echo "localhost :" >&3
echo $HOSTNAME"	local:" >&3
echo $HOSTNAME".localnet	local:" >&3
echo "*		wl2k:localhost" >&3
exec 3>&-

#Reload transport file
postmap /etc/postfix/transport

cd /etc
$CONFIG_FILE=mailname
ChkFile_Exist $CONFIG_FILE

# Create mailname file
echo $HOSTNAME".localnet" > mailname

$CONFIG_FILE=aliases
ChkFile_Exist $CONFIG_FILE

# Create postfix aliases file using file descriptor (fd) 3
exec 3<> aliases
echo "# /etc/aliases" >&3
echo "root: "$INST_UID >&3
echo "mailer-daemon" >&3
echo "postmaster: "$INST_UID >&3
echo "nobody: root" >&3
echo "hostmaster: root" >&3
echo "usenet: root" >&3
echo "news: root" >&3
echo "webmaster: root" >&3
echo "www: root" >&3
echo "ftp: root" >&3
echo "abuse: root" >&3
echo "noc: root" >&3
echo "security: root" >&3
exec 3>&-

# Recreate aliases.db
newaliases
# Configure master.cf
# Check if postfix master file has been modified
grep "wl2k" /etc/postfix/master.cf  > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   {
      echo "wl2k      unix  -       n       n       -       1      pipe"
      echo "  flags=XFRhu user=$USER argv=/usr/local/libexec/mail.wl2k -m"
   } >> /etc/postfix/master.cf
else
   echo " /etc/postfix/master.cf already modified."
fi

# Configure main.cf
cd /etc/postfix
$CONFIG_FILE=main.cf
ChkFile_Exist $CONFIG_FILE
# use awk to modify necessary entris in main.cf use comment below as reference
#awk -F '[ \t]*=[ \t]*' '$1=="keytodelete" { next } $1=="keytomodify" { print "keytomodify=newvalue" ; next } { print } END { print "keytoappend=value" }' "$CONFIG_FILE" >"$CONFIG_FILE~"
awk -v key="myhostname" -v name="$HOSTNAME" -F '[ \t]*=[ \t]*' '$1==key { print $1" = "name ; next } { print }' "$CONFIG_FILE" >"$CONFIG_FILE~"
awk -v key="mydestination" -v name="$HOSTNAME, $HOSTNAME.localnet, localhost.localnet, localhost" -F '[ \t]*=[ \t]*' '$1==key { print $1" = "name ; next } { print }' "$CONFIG_FILE~"
awk -v key="mynetworks" -v name="127.0.0.0/8" -F '[ \t]*=[ \t]*' '$1==key { print $1" = "name ; next } { print }' "$CONFIG_FILE~"
awk -v key="inet_protocols" -v name="ipv4" -F '[ \t]*=[ \t]*' '$1==key { print $1" = "name ; next } { print }' "$CONFIG_FILE~"
awk -v key="home_mailbox" -v name="maildir" -F '[ \t]*=[ \t]*' '$1==key { print $1" = "name ; next } { print }' "$CONFIG_FILE~"
mv "$CONFIG_FILE~" "$CONFIG_FILE" || echo "File move failed (permissions? disk space?)"



}

function ChkFile_Exist()
# Check for file and make dated backup before continuing.
{
if [ -e "$1" ]; then
  cp -p "$1" "$1.orig.$(date \"+%Y%m%d_%H%M%S\")"
fi
}

# Main
echo -e "${BluW}\t\n\t  Install Paclink-Unix \n${Yellow}\t     version 1.0.0  \t\n\t \n${White}   by Scott Newton ( W4CSN )  \n${Red}               snewton86@gmail.com \n${Reset}"
Chk_Root
Install_Tools
Download_paclink
Configure_Groups
Configure_postfix
exit 0

