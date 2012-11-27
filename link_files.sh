#!/bin/sh
base_dir=`pwd`/$(dirname $0)/src
cd $HOME
ln -sfn $base_dir/.[a-z]* ./
