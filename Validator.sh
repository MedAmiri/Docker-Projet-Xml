#!/bin/sh

if [ -n $2 ]; then
	xmllint --noout $1 --schema $2
elif [ -z $2 ]; then 
	xmllint --noout $1 
fi

