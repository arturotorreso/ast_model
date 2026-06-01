#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);
my ($in)=@ARGV;

my %key;
open IN,"$Bin/arg.drug";
while(<IN>){
    chomp;
	next if $_=~/#/;
	my @or=split /\t/;
	foreach my $i (@or[1..$#or]){
		$key{$i}=1;
	}
}
close IN; 

open IN,$in;
my $line=<IN>;
chomp $line;
my @title=split /\t/,$line;
my %hash;
my %lab;
while(<IN>){
	chomp;
	my @or=split /\t/;
	my @vv=split /,/,$or[-1];
	my @ll=split /\|/,$vv[0];
	next if $vv[0]=~/LOW/;
	next unless $ll[3];
	unless($key{$ll[3]}){
		next;
	}
	$ll[10] || next;
	#my $label=$ll[3] eq "oprD"  ? $vv[0]=~/HIGH/ ? "$ll[3](HIGH)" : "$ll[3]($ll[10]):$ll[2]" : "$ll[3]($ll[10]):$ll[2]";
	my $label=$vv[0]=~/HIGH/ ? "$ll[3](HIGH)" : "$ll[3]($ll[10]):$ll[2]";
	$lab{$label}=1;
	foreach my $i (1..$#or-1){
		$hash{$title[$i]}{$label}+=$or[$i];
	}
}
close IN;
my @lbs=sort keys %lab;
print "#var\t",join("\t",@title[1..$#title-1]),"\n";
foreach my $l (@lbs){
	print $l;
	foreach my $s (@title[1..$#title-1]){
		$hash{$s}{$l}||=0;
		$hash{$s}{$l}=1 if $hash{$s}{$l}>0;
		print "\t",$hash{$s}{$l};
	}
	print "\n";
}
