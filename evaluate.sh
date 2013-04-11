#!/bin/bash
#
# Evaluate the classifier's performance
#

ALLFILES="highly-cited-bio-all.txt highly-cited-cs-all.txt"
GREEKFILES="highly-cited-bio-el.txt highly-cited-el.txt"

# Greek highly cited in cs-all: 5
# ALEXOPOULOS PAPADIMITRIOU POLYDOROS VOLAKIS YANNAKAKIS
# Greek highly cited in bio-all: 3
# CHROUSOS KYRIAKIS MANIATIS
fgrep -v -f 'greek-in-all.txt' $ALLFILES >nongreek.txt

NONGREEK=`wc -l <nongreek.txt`
GREEK=`cat $GREEKFILES | wc -l`

# Count true and false positives and negatives
TP=$(perl classify.pl $GREEKFILES | wc -l)
FP=$(perl classify.pl nongreek.txt | wc -l)
TN=$(expr $NONGREEK - $FP)
FN=$(expr $GREEK - $TP)

echo -n 'Precision: '
echo "$TP / ($TP + $FP)" | bc -l

echo -n 'Recall: '
echo "$TP / ($TP + $FN)" | bc -l

echo -n 'Specificity: '
echo "$TN / ($TN + $FP)" | bc -l

echo -n 'Accuracy: '
echo "($TP + $TN) / ($TP + $TN + $FP + $FN)" | bc -l

# Matthews correlation coefficient
echo -n 'MCC: '
echo "($TP * $TN - $FP * $FN) / sqrt(($TP + $FP) * ($TP + $FN) * ($TN + $FP) * ($TN + $FN))" | bc -l
