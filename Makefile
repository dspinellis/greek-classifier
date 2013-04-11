INSTPREFIX=/usr/local

install:
	mkdir -p $(INSTPREFIX)/lib/greek-classifier
	install -m 644 ngram.all ngram.el $(INSTPREFIX)/lib/greek-classifier/
	install greek-classifier.pl $(INSTPREFIX)/bin/greek-classifier

# The following rules serve only documentation purposes
ngram.el: greek-classifier.pl
	awk -F';'  '{print $$1}' onomata_epitheta.csv | \
	sed '1d;s/"//g;s/  *$$//' | \
	grconv -S UTF-8 -x transcribe | \
	grep -v '[^A-Z]' | \
	perl greek-classifier.pl -g | \
	sort -t'	' -k2gr >$@

ngram.all: mixed-surnames.txt greek-classifier.pl
	perl greek-classifier.pl -g $< | \
	sort -t'	' -k2gr >$@

# Extract mixed names
mixed-surnames.txt:
	echo 'select name from names;' | \
	sqlite3 /cygdrive/c/vol/geonames/names.sqlite | \
	grep -v '[^A-Za-z]' | \
	tr a-z A-Z >mixed-surnames.txt
