#!/bin/bash
if [ ! -d testo ]; then
    mkdir testo
fi
# A=tcp://127.0.0.1:9467
# JULIA_NUM_THREADS=4 julia src/chloe_distributed.jl -a $A --level=warn &
for f in $(ls testfa/*.fa)
do
    echo "annotating $f"
    python bin/chloe.py annotate -o testo $f 
    bn=$(basename $f)
    o="${bn%.*}.sff"
    echo "diffing testfa/$o testo/$o"
    diff testfa/$o testo/$o
    if [ $? -eq 0 ]; then
        echo -e "\e[32m******** test OK ***********\e[0m"
    else
        echo -e "\e[31m******** test FAILED *******\e[0m"
    fi
done
# python bin/chloe.py terminate -a $A
rm -rf testo