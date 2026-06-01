#!usr/bin/perl -w
use strict;


my ($gpa,$va)=@ARGV;


my %features;
open IN,$gpa;
my %ast;
my %hash;
my $title=<IN>;
chomp $title;
my @tt=split /\t/,$title;
foreach my $f (@tt[2..$#tt]){
	$features{$f}=1;
}
while(<IN>){
	chomp;
	my @or=split /\t/;
	$ast{$or[1]}=$or[0];
	foreach my $i (2..$#or){
		$hash{$or[1]}{$tt[$i]}=$or[$i];
	}
}
close IN;

open IN,$va;
my $title1=<IN>;
chomp $title1;
my @tt1=split /\t/,$title1;
foreach my $f (@tt1[2..$#tt1]){
	$features{$f}=1;
}
while(<IN>){
	chomp;
	my @or=split /\t/;
	$ast{$or[1]}=$or[0];
	foreach my $i (2..$#or){
		$hash{$or[1]}{$tt1[$i]}=$or[$i];
	}
}
close IN;

my @features=sort keys %features;
print "AST\tARG\t",join("\t",@features),"\n";
foreach my $s ( sort keys %hash){
	print $ast{$s},"\t",$s;
	foreach my $f (@features){
		$hash{$s}{$f}||=0;
		print "\t",$hash{$s}{$f};
	}
	print "\n";
}

