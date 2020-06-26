#!/bin/bash

if [ "$#" -ne 3 ]
then
    echo "Usage (example): `basename $0` benchRT gamma Linux"
    echo "The reference will be built from the benchRT/'output' folder content, based on the list of files provided in the reference/gamma.txt file. Linux is the architecture (not mandatory)."
    exit 1
fi

echo
echo "The reference will be built from the $1/'output' folder content, based on the list of files provided in the reference/$1_$2.txt file. $3 is the architecture (not mandatory)."
echo
echo "This script should be launched from a git repository."

echo "Current directory:"
pwd
echo

echo "Printing the three parameters for debugging:"
echo $1
echo $2
echo $3


# This script should be launched locally, from its containing folder
# Note : ${BASH_SOURCE[0]} contains this script name
# Tests -ge instead of -eq to include the case of there are backup versions of the script in the current folder.
if [ `ls | grep ${BASH_SOURCE[0]##*/} | wc -l` -ge 1 ]; then
    echo "This script is launched locally, from its containing folder."
    BENCHMARKS_DIRECTORY=`pwd`
# exit otherwise
else
    echo "You are launching gate_make_test_ref.sh from an improper location. Please launch this script locally, from its containing folder."
    exit 1
fi

echo
echo "Benchmarks directory:"
echo $BENCHMARKS_DIRECTORY
echo
cd $BENCHMARKS_DIRECTORY/$1/

echo "Working directory:"
pwd

echo
echo

echo "----------------------------------------------------"
echo "Reference archive creation:"
mkdir test_ref

# Each line of the $1_$2.txt file is splitted (separator is space) and stored in an array 'WORD'
while read -a WORD
do
    echo "${WORD[@]}"

    cp output/${WORD[1]} test_ref

done <reference/$1_$2.txt

cp reference/$1_$2.txt test_ref
git add reference/$1_$2.txt

echo "This reference was created by launching a Gate simulation on" >reference/$1_$2_ref.txt
echo $(date) >>reference/$1_$2_ref.txt
echo "with the configuration file benchmarks/$1/mac/$2.mac" >>reference/$1_$2_ref.txt
echo "from the commit" >>reference/$1_$2_ref.txt
echo $(git log |head -1) >>reference/$1_$2_ref.txt
echo "with the version of gcc" >>reference/$1_$2_ref.txt
echo $(gcc --version |head -1) >>reference/$1_$2_ref.txt
echo "on the architecture $3" >>reference/$1_$2_ref.txt
echo $(uname -a) >>reference/$1_$2_ref.txt

cp reference/$1_$2_ref.txt test_ref
git add reference/$1_$2_ref.txt

cd test_ref
tar cvzf $1_$2-reference.tgz *
cd ..
mv test_ref/$1_$2-reference.tgz reference
rm -rf test_ref
echo "----------------------------------------------------"

cd reference

echo
echo "----------------------------------------------------"
echo "sha512sum creation."

if test "$(uname)" = "Darwin"
then
    sha512 -q $1_$2-reference.tgz >$1_$2-reference.tgz.sha512
else
    echo $(sha512sum $1_$2-reference.tgz | cut -f 1-1 -d ' ') >$1_$2-reference.tgz.sha512
fi

git add $1_$2-reference.tgz.sha512
echo "----------------------------------------------------"

echo
echo "----------------------------------------------------"
if [ `grep $1_$2 ../../CMakeLists.txt |grep ADD_TEST|wc -l` -eq 0 ];
then
    echo "Addition of a new external reference data."

    echo "$1_$2-reference.tgz.sha512-stamp" >> .gitignore
    echo "$1_$2-reference.tgz"           >> .gitignore
    git add .gitignore

    echo "
if(BUILD_TESTING)
  GateAddBenchmarkData(\"DATA{$1/reference/$1_$2-reference.tgz}\")
  ADD_TEST(NAME $1_$2
    COMMAND /bin/bash  \${Gate_SOURCE_DIR}/benchmarks/gate_run_test.sh $1 $2 \${Gate_SOURCE_DIR})
endif(BUILD_TESTING)" >> ../../CMakeLists.txt
    git add ../../CMakeLists.txt

else
    echo "Already existing external reference data."
fi
echo "----------------------------------------------------"

cd ../..

echo
echo "----------------------------------------------------"
echo "Here is a 'git status':"
git status
echo "Don't forget to commit and push the local modifications, especially the new files."
echo
echo "Don't forget to upload your data $1_$2-reference.tgz (from $1/reference folder) in https://data.kitware.com/#collection/5be2bffb8d777f21798e28bb/folder/5be2c0298d777f21798e28d3"

exit 0
