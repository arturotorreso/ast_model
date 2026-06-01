#!usr/bin/perl -w
use strict;
my ($list)=@ARGV;

my %hash;
open IN,$list;
my %features;
my @samples;
while(<IN>){
	chomp;
	open FF,$_;
	my $one=<FF>;chomp $one;
	my @title=split /\t/,$one;
	unless (@samples){
		@samples=@title[1..$#title];
	}
	while(my $l=<FF>){
		chomp $l;
		my @arr=split /\t/,$l;
		$features{$arr[0]}=1;
		foreach my $i (1..$#arr){
			$hash{$title[$i]}{$arr[0]}+=$arr[$i];
		}
	}
	close FF;
}
close IN;

print "#var\t",join("\t",@samples),"\n";
foreach my $f (sort keys %features){
	print $f;
	foreach my $s (@samples){
		$hash{$s}{$f}||=0;
		my $v=$hash{$s}{$f};
		$v= $v >= 1 ? 1 : 0 ; #这里可以增加阈值设置，即检出变异位点支持的模板数目
		print "\t",$v;
	}
	print "\n";
}
