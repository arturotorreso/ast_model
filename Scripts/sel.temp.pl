#!usr/bin/perl -w
use strict;

my  ($all,$in)=@ARGV;
#sel oprD ref
open IN,$all;
my %id;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$id{$or[0]}=$or[1];
}
close IN;

my %hash;
open IN,$in;
while(<IN>){
	chomp;
	my @or=split /\//;
	my $sam=$or[-3];
	my $f=$1 if $or[-1]=~/$sam\.(\S+).filter.anno.vcf/;
	if($id{$sam}){
		if($id{$sam} eq $f){
			print $_,"\n";
		}
	}else{
		if($f eq "PAO1"){
			print $_,"\n";
		}
	}
}
close IN;
