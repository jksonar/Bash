#!/bin/bash 
# This script will echo command for run on windows CMD program to manage users related task.

usrC=1
if [ -z $1 ];then
	echo "$0 -c/-r/-d userlist.txt"
	exit 2
elif [ -z $2 ];then
	echo "$0 -c/-r/-d userlist.txt"
	exit 2
elif [ ! -f $2 ];then
	echo "$2 no such file"
	exit 2
else
	uName=$(sort $2)
fi

function deleteUser(){
	if [ -f /root/deleteuser.txt ];then
		rm -f /root/deleteuser.txt
	fi
	for i in $uName
	do
		echo "net user ${i} /delete"
		echo "del C:\\Users\\${i} /F /S /Q"
		echo "rd C:\\Users\\${i} /S /Q"
		echo -e "${usrC}) username is deleted ${i}" >> /root/deleteuser.txt
		((usrC++))
	done
	echo "pause"
}
function createUser(){
	if [ -f /root/user.txt ];then
		rm -f /root/user.txt
	fi

	for i in $uName
	do
		uPasswd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
		echo -e "${usrC}) username: ${i}\npassword: ${uPasswd:0:6}@${usrC}\n" >> /root/user.txt
		echo "net user ${i} ${uPasswd:0:6}@${usrC} /add"
		((usrC++))
	done
	echo "pause"
}

function reSetPasswd(){
	if [ -f /root/user_reset.txt ];then
		rm -f /root/user_reset.txt
	fi
	
	for i in $uName
	do
		#uPasswd=$( pwgen 8 1)
		uPasswd=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
		echo -e "${usrC}) username: ${i}\npassword: ${uPasswd:0:6}@${usrC}\n" >> /root/user_reset.txt
		echo "net user ${i} ${uPasswd:0:6}@${usrC}"
		((usrC++))
	done
	echo "pause"
}
case $1 in
	--create|-c|--Create|--CREATE)
		createUser
	;;
	--reset|-r|--Reset|--RESET)
		reSetPasswd
	;;
	--delete|-d|--Delete|--DELETE)
		deleteUser
	;;
	--help|-h|--HELP)
		echo "$0 -c/-r/-d userlist.txt"
	;;
	*)
		echo "$0 -c/-r/-d userlist.txt"
	;;
esac

