#!/bin/bash
FLAG=0
MONITORED_FILE=$1
TEMP_FILE=.$1.tmp

[ ! -f $TEMP_FILE ] && touch -r $MONITORED_FILE $TEMP_FILE

while [ $FLAG == 0 ]; do
  sleep 1
  [ $MONITORED_FILE -nt $TEMP_FILE ] && echo "running tests ..." && ./test.sh
  touch -r $MONITORED_FILE $TEMP_FILE
done
