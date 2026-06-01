#!usr/bin/perl -w
use strict;

my ($in)=@ARGV;

open IN,$in;
while(<IN>){
	chomp;
	if ($_=~/^#/){
		print $_,"\n";
		next;
	}else{
		my @or=split /\t/;
			if ($or[4] ne "." ){
				my @aa=split /:/,$or[-1];
				next if $aa[-1] < 0.05;
				print $_,"\n";
			}
	}
}
close IN;
