ngram.el: ngram.pl
	awk -F';'  '{print $$1}' onomata_epitheta.csv | \
	sed '1d;s/"//g;s/  *$$//' | \
	grconv -S UTF-8 -x transcribe | \
	grep -v '[^A-Z]' | \
	perl ngram.pl | \
	sort -t'	' -k2gr >$@

sample.txt: greek.dg
	cat CCRacist/*.txt ; 

train.txt: sample.txt
	head -2000 $< >$@

test.txt: sample.txt
	tail -2000 $< >$@

ngram.all: mixed-surnames.txt
	perl ngram.pl $< | \
	sort -t'	' -k2gr >$@

# Extract mixed names
mixed-surnames.txt:
	echo 'select name from names;' | \
	sqlite3 /cygdrive/c/vol/geonames/names.sqlite | \
	grep -v '[^A-Za-z]' | \
	tr a-z A-Z >mixed-surnames.txt
