#!/bin/bash -e

MYFILE=$(mktemp tmpXXXX)
MYFILE2=$(mktemp tmpXXXX)
trap "rm -f $MYFILE $MYFILE2 *jump" EXIT

msize() {
    case $(uname) in
        (Darwin | *BSD*)
            stat -Lf %z -- "$MYFILE";;
        (*) stat -c %s -- "$MYFILE"
    esac
}

case "$1" in
    e)
        tar zcf $MYFILE $2
        SIZE=$(msize)
        echo -n pass: 
        read -s password
        echo $password | openssl aes-256-cbc -a -salt -in $MYFILE -out $MYFILE2 -md sha256 -pass stdin -pbkdf2
        echo $password | openssl aes-256-cbc -a -salt -in $MYFILE2 -out $3.jump.pub -md sha256 -pass stdin -pbkdf2
        for n in $(seq 1000 1 1100); do
           STR=$( printf %04d "$n" ).jump
           if [ "$STR" != "$3".jump ]; then
               dd if=/dev/urandom of=$STR bs=1 count=$SIZE
           fi
        done
        for i in $(ls -d *jump)
        do
            echo $RANDOM | openssl aes-256-cbc -a -salt -in $i -out $MYFILE2 -pass stdin -md sha256 -pbkdf2
            echo $RANDOM | openssl aes-256-cbc -a -salt -in $MYFILE2 -out $i.pub -pass stdin -md sha256 -pbkdf2
        done
        ;;
    d)
        echo -n pass: 
        read -s password
        echo $password | openssl aes-256-cbc -a -d -in $2 -out $MYFILE2 -md sha256 -pass stdin -pbkdf2
        echo $password | openssl aes-256-cbc -a -d -in $MYFILE2 -out $MYFILE -md sha256 -pass stdin -pbkdf2
        tar xzf $MYFILE
        ;;
    *)
	echo "usage $0 <e|d> <target> <id>"
esac

