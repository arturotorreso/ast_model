#!usr/bin/perl -w
use strict;

my ($sample,$table)=@ARGV;
@ARGV || die "perl $0 <sample.list> <table> > sel.table\n";
my %hash;
open IN,$sample;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$hash{$or[0]}=1;
}
close IN;

open IN,$table;
my $one=<IN>;
my %loci;
chomp $one;
my @arr=split /\t/,$one;
my @selsample;
foreach  my $i (0..$#arr){
	if($hash{$arr[$i]}){
		$loci{$i}=1;
		push @selsample,$arr[$i];
	}
}
print join("\t",@selsample),"\n";
while(<IN>){
	chomp;
	my @or=split /\t/;
	print $or[0];
	foreach my $i (1..$#or){
		if($loci{$i}){
			print "\t",$or[$i];
		}
	}
	print "\n";
}
