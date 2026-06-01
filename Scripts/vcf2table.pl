#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);

my ($in)=@ARGV;

my %key;
open IN,"$Bin/focus.gene.list";
while(<IN>){
	chomp;
	$key{$_}=1;
}
close IN;

my %samples;
my %samvar;
my %varsort;
my %var;
open IN,$in;
while(<IN>){
	chomp;
	my @ss=split /\//;
	$samples{$ss[-3]}=1;
	open FF,$_;
	while(my $l=<FF>){
		chomp $l;
		next if $l=~/^#/;
		my @or=split /\t/,$l;
		my @aa=split /\|/,$or[-3];
		if($key{$aa[3]}){
			$var{"$or[1]($or[3]-\>$or[4])"}{$or[-3]}=1;
			$varsort{"$or[1]($or[3]-\>$or[4])"}=$or[1];
			$samvar{$ss[-3]}{"$or[1]($or[3]-\>$or[4])"}=1;
		}
	}
	close FF;
}
close IN;

my %var2;
foreach my $v (sort keys %var){
	$var2{$v}=join(";",sort keys %{$var{$v}});
}

my @samples=sort keys %samples;
print "#var\t",join("\t",@samples),"\tSnpEffAnno\n";
foreach my $v (sort {$varsort{$a} <=> $varsort{$b}} keys %varsort){
	print $v;
	foreach my $s (@samples){
		$samvar{$s}{$v}||=0;
		print "\t",$samvar{$s}{$v};
	}
	print "\t",$var2{$v};
	print "\n";
}
