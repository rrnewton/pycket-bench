#!/bin/bash

echo "Begin running jenkins benchmark script for Pycket.  First use regression script to build packages:"
set -x
set -e

echo "On linux platforms, check CPU affinity:"
taskset -pc $$ || echo ok

echo "Also check load:"
sar 2 2 || echo ok

echo "And who"
who -a || echo ok

# CONVENTION: The working directory is passed as the first argument.
CHECKOUT=$1
shift || echo ok

if [ "$CHECKOUT" == "" ]; then
  CHECKOUT=`pwd`
fi
set -e

# ----------------------------------------
# RRN: This doesn't work yet -- too many dependencies:
# echo "\nFirst building all the compilers."
# (cd ..; ./setup.sh)

cd "$CHECKOUT"/../pycket/
if ! [ -d ./pypy ]; then 
  time hg clone https://bitbucket.org/pypy/pypy
fi
(cd pypy && hg checkout 74619)

# Eventually, follow this convention:
# NOTEST=1 ./.jenkins_script.sh -j

# ----------------------------------------
echo "\nReturned to benchmarking script."
echo "Running benchmarks remotely on server `hostname`"

# Switch to where the benchmarks are
# ----------------------------------------
cd "$CHECKOUT"/

# Fetch data and build benchmark runner:
# make

export TRIALS=3

if [ "$MACHINECLASS" == "cutter" ]; then
  # Using generic uploader because we're over limit:
  # Generic 1:
  CID=905767673358.apps.googleusercontent.com
  SEC=2a2H57dBggubW1_rqglC7jtK
elif [ "$MACHINECLASS" == "lh008" ]; then 
  # Using generic uploader because we're over limit:
  # Generic 2:
  CID=546809307027-8tm2lp5gtqg5o3pn3s016gd6467cf7j3.apps.googleusercontent.com
  SEC=148aQ08EPpgkb0DiYVLoT9X2
else
  # Generic 3:
  CID=759282369766-ijonhc4662ot2qos4lgud0e0sltjshlj.apps.googleusercontent.com
  SEC=yI8GfZXsHPrW44udqklCHeDH
fi

TABLENAME=Pycket_benchmarks

if [ "$MACHINECLASS" == "" ]; then
    export MACHINECLASS=`hostname -s`
fi

# Soon these will turn into proper hackage dependencies:
HSBDEPS="../HSBencher/hsbencher ../HSBencher/hsbencher-fusion ../HSBencher/hgdata"

cabal sandbox init
cabal install $HSBDEPS --bindir=. --program-suffix=.exe -j

./run-pycket-benchmarks.exe --keepgoing --trials=$TRIALS --fusion-upload --name=$TABLENAME --clientid=$CID --clientsecret=$SEC --hostname=$MACHINECLASS $*
