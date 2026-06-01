#!usr/bin/perl -w
use strict;

my ($in)=@ARGV;

open IN,$in;
my $one=<IN>;
my $two=<IN>;
print $one;
print $two;
while(<IN>){
	chomp;
	my @or=split /\t/;
	my $s=0;
	foreach my $i (@or[1..$#or]){
		$s+=$i;
	}
	if($s==0){
		next;
	}else{
		print $_,"\n";
	}
}
close IN;
