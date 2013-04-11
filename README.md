This is a command-line tool. It reads ASCII text from the specified files
(or its standard input), and will print on the standard output lines
that (probably) match a Greek surname. Various command-line options can
direct the matching to be performed on specified fields or the longest
part of a field.

# Installation
Run ```make install``

# Execution
The classifier requires two files containing n-grams derived from
large collections of Greek and international surnames.
Therefore, run it from the directory containing the source code
(as ```perl greek-classifier.pl```), or install it in order to run it
from any directory (as ```greek-classifier```).

## Example
```
perl greek-classifier.pl highly-cited-cs-all.txt
ALAMOUTI
ALEXOPOULOS
CURTIS
DENNIS
KOMLOS
PAPADIMITRIOU
POLYDOROS
TRIVEDI
VALIANT
VARANASI
VARDI
VAZIRANI
VOLAKIS
YANNAKAKIS
```

# Command-line options
```
greek-classifier [-d distance] [-k field] [-l] [-t separator] [file ...]
greek-classifier -g [file ...]
-d distance	Specify the distance that generates a match (default 9)
		Higher values increase precision (fewer wrong entries)
		Lower values increase recall (fewer missed entries)
-D		Print the calculated distances
-g		Generate an n-gram table
-k field	Specify field to match; first is 1 (default whole line)
-l		Match only line's / field's longest word
-t separator	Specify field separator RE (space characters by default)
-u		Normalize matched part to uppercase
-w		Print matching word, rather than matching line
```
