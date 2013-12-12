#!/usr/bin/perl
#
# Read surnames from standard input and print those that are Greek
#
#  Copyright 2013 Diomidis Spinellis
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

use strict;
use warnings;
use Getopt::Std;

$main::VERSION = '1.0';
# Exit after command processing error
$Getopt::Std::STANDARD_HELP_VERSION = 1;

my $max_gram = 4;

our($opt_D, $opt_d, $opt_g, $opt_k, $opt_l, $opt_r, $opt_t, $opt_u, $opt_w);

# Default distance
$opt_d = 9;

# Default field separator
$opt_t = '\s+';

if (!getopts('Dd:gk:lr:t:uw')) {
	main::HELP_MESSAGE(*STDERR);
	exit 1;
}

sub
main::HELP_MESSAGE
{
	my ($fh) = @_;
	print $fh qq{
Usage:
$0 [-d distance] [-k field] [-l] [-t separator] [file ...]
$0 -g [file ...]
-d distance	Specify the distance that generates a match (default 9)
		Higher values increase precision (fewer wrong entries)
		Lower values increase recall (fewer missed entries)
-D		Print the calculated distances
-g		Generate an n-gram table
-k field	Specify field to match; first is 1 (default whole line)
-l		Match only line's / field's longest word
-r rec-sep	Specify record separator string (default is newline)
		Character escapes (e.g. \\r) are recognized
-t field-sep	Specify field separator RE (space characters by default)
-u		Normalize matched part to uppercase
-w		Print matching word, rather than matching line
};
}

if ($opt_g) {
	generate();
	exit 0;
}

my %greek_ng;
my %all_ng;

read_ngram('ngram.el', \%greek_ng);
read_ngram('ngram.all', \%all_ng);

# Set record separator, recognizing character escapes
local $/ = eval(qq{"$opt_r"}) if defined($opt_r);

while(<>) {
	chop;
	my $field;
	my $word;

	# Split fields
	if ($opt_k) {
		my @fields = split(/$opt_t/);
		$field = $fields[$opt_k - 1];
	} else {
		$field = $_;
	}

	# Select longest
	if ($opt_l) {
		my @parts = split(/[^\w]/, $field);
		my $lfield = '';
		for my $try (@parts) {
			$lfield = $try if (length($try) > length($lfield));
		}
		$field = $lfield;
	}

	$field =~ y/[a-z]/[A-Z]/ if ($opt_u);

	next if (length($field) < 2);

	$word= "^$field\$";

	# Print result if match
	if(delta($word, \%greek_ng, \%all_ng) > $opt_d) {
		if ($opt_w) {
			print "$field\n";
		} else {
			print "$_\n";
		}
	}
	if ($opt_D) {
		print "$word GD:", distance($word, \%greek_ng), "\n";
		print "$word AD:", distance($word, \%all_ng), "\n";
	}
}

# Given two references to arrays of n-gram probabilities
# return the difference in their distance
sub
delta
{
	my ($word, $ngp0, $ngp1) = @_;

	return distance($word, $ngp1) - distance($word, $ngp0);
}

sub
sqr
{
	my ($n) = @_;
	return $n * $n;
}

# Given a reference to an array of n-gram probabilities
# return the distance measure of the word from the array
sub
distance
{
	my ($word, $ngp) = @_;

	my $sum = 0;
	for (my $n = 2; $n <= $max_gram; $n++) {
		# Relative frequency of each ngram in word
		my $fA = 1 / (length($word) - $n + 1);
		for (my $s = 0; $s < length($word) - $n + 1; $s++) {
			my $ngram = substr($word, $s, $n);
			# Relative frequency of ngram in training set
			my $fa = (exists($ngp->{$ngram})) ?
				$ngp->{$ngram} * 5 : 0;
			$sum += sqr(($max_gram + 1 - $n) * ($fa - $fA) / ($fA + $fa));
			#print "fa=$fa fA=$fA sum=$sum\n";
		}
	}
	return $sum;
}

# Read a tab-separated file of n-gram probabilities into the specified
# hash reference
sub
read_ngram
{
	my($fname, $ngp) = @_;

	my $in;

	open($in, '<', "/usr/local/lib/greek-classifier/$fname") ||
	open($in, '<', "/usr/lib/greek-classifier/$fname") ||
	open($in, '<', $fname) || die "Unable to open $fname: $_\n";
	while (<$in>) {
		chop;
		my ($ngram, $prob) = split(/\t/);
		$ngp->{$ngram} = $prob;
	}
}

# Generate an n-gram table by calculating n-gram frequencies
# for standard input or the specified input files
sub
generate
{
	my @gram;
	my @count;

	while (<>) {
		chop;
		# Beginning and end have additional significance
		s/^/^/;
		s/$/\$/;
		for (my $n = 2; $n <= $max_gram; $n++) {
			for (my $s = 0; $s < length($_) - $n + 1; $s++) {
				$gram[$n]{substr($_, $s, $n)}++;
				$count[$n]++;
			}
		}
	}

	# Print results
	for (my $n = 2; $n <= $max_gram; $n++) {
		for my $g (keys %{$gram[$n]}) {
			print "$g\t", $gram[$n]{$g} / $count[$n], "\n";
		}
	}
}
