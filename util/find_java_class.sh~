#!/bin/bash

usage="Uso:        findJavaClass directory ClassName   "
IFS='
'
if [ $# -lt 2 ] ; then
    echo $usage
    exit 1
fi

if [ ! -d "$1" ] ; then
    echo "Diretorio nao existe"
    exit 1    
fi

find "${1}" -type f  -name \*.jar | while read jar_file ; 
do
    found_class=`unzip -l $jar_file | awk '{print $4}' | grep  $2`
    num_classes=`echo $found_class | wc -c`
    if [ $num_classes -gt 1 ] ; then 
        echo ""
        echo "Arquivo:"
        echo "    $jar_file"
        echo "Classes:"
        echo $found_class | sed 's/\ /\n/g' | sed 's/^.*/\ \ \ \ &/g'
    fi
done
