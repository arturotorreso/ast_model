#!usr/bin/perl -w
use strict;

my ($db,$in)=@ARGV;

my %hash;
open IN,$db;
my $title=<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$hash{$or[0]}{$or[3]}=$_;
}
close IN;

open IN,$in;
my $one=<IN>;
chomp $one;
print $one,"\tdrug\t",$title;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$or[0]=~s/#//g;
	foreach my $drug(qw/imipenem meropenem/){
		if($hash{$or[0]}{$drug}){
			print $_,"\t",$drug,"\t",$hash{$or[0]}{$drug},"\n";
		}else{
			print $_,"\t",$drug,"\t-"x16,"\n";
		}
	}
}
close IN;
