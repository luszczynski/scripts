#!/bin/bash

find . -name *.jar -exec grep -l $1 {} \;
