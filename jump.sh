#!/bin/bash -e

TMPFILE1=$(mktemp tmpXXXX)
TMPFILE2=$(mktemp tmpXXXX)
trap "rm -f $TMPFILE1 $TMPFILE2 *jump" EXIT

msize() {
    case $(uname) in
        (Darwin | *BSD*)
            stat -Lf %z -- "$TMPFILE1";;
        (*) stat -c %s -- "$TMPFILE1"
    esac
}

case "$1" in
    e)
        tar zcf $TMPFILE1 $2
        SIZE=$(msize)
        echo -n pass: 
        read -s password
        echo $password | openssl aes-256-cbc -a -salt -in $TMPFILE1 -out $TMPFILE2 -md sha256 -pass stdin -pbkdf2
        echo $password | openssl aes-256-cbc -a -salt -in $TMPFILE2 -out $3.jump.pub -md sha256 -pass stdin -pbkdf2
        for n in $(seq 1000 1 1100); do
           STR=$( printf %04d "$n" ).jump
           if [ "$STR" != "$3".jump ]; then
               dd if=/dev/urandom of=$STR bs=1 count=$SIZE
           fi
        done
        for i in $(ls -d *jump)
        do
            echo $RANDOM | openssl aes-256-cbc -a -salt -in $i -out $TMPFILE2 -pass stdin -md sha256 -pbkdf2
            echo $RANDOM | openssl aes-256-cbc -a -salt -in $TMPFILE2 -out $i.pub -pass stdin -md sha256 -pbkdf2
        done
        ;;
    d)
        echo -n pass: 
        read -s password
        echo $password | openssl aes-256-cbc -a -d -in $2.jump.pub -out $TMPFILE2 -md sha256 -pass stdin -pbkdf2
        echo $password | openssl aes-256-cbc -a -d -in $TMPFILE2 -out $TMPFILE1 -md sha256 -pass stdin -pbkdf2
        tar xzf $TMPFILE1
        ;;
    *)
	echo "usage $0 e <target> <id>"
	echo "usage $0 d <id>"
esac

