greek.dg: ngram.pl
	awk -F'	' '{print $$1 "\n" $$2}' grnames.txt | \
	grconv -x transcribe | \
	tr ' ' \\n | \
	grep -v '[^A-Z^\$$]' | \
	perl ngram.pl | \
	sort -t'	' -k2gr >$@

sample.txt: greek.dg
	cat CCRacist/*.txt ; 

train.txt: sample.txt
	head -2000 $< >$@

test.txt: sample.txt
	tail -2000 $< >$@

# Extract mixed names
mixed-names.txt:
	echo 'select name from names;' | \
	sqlite3 /cygdrive/c/vol/geonames/names.sqlite | \
	grep -v '[^A-Za-z]' | \
	tr a-z A-Z >mixed-names.txt
