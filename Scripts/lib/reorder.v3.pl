#!usr/bin/perl -w
use strict;

my ($order,$table)=@ARGV;
@ARGV|| die "perl $0 <order.list> <table> > output 根据order的顺序对table进行排序,同时根据样本score和对样本排序 \n";
open IN,$order;
my @samples;
while(<IN>){
	chomp;
	my @or=split /\t/;
	next if $or[1]==0;
	push @samples,$or[0];
}
close IN;
push @samples,"AST";
#push @samples,"predict";

my %ori;
open IN,$table;
my $title=<IN>;chomp $title;
my @jj=split /\t/,$title;
my %filter;
foreach my $j (@jj){
	$filter{$j}=1;
}
my @sample_filter;
foreach my $i (@samples){
	push @sample_filter,$i if $filter{$i};
}
while(<IN>){
	chomp;
	my @or=split /\t/;
	$ori{$or[0]}=$_;
}
close IN;

open IN,$table;
my $one=<IN>;
chomp $one;
my @tt=split /\t/,$one;
print "Genomes\t",join("\t",@sample_filter),"\tPredict\n";
my %hash;
my @order;
foreach my $s (@sample_filter){
	foreach my $i (1..$#tt){
		if ($tt[$i] eq $s){
			push @order,$i;
			last;
		}
	}
}
while(<IN>){
	chomp;
	my @or=split /\t/;
	print $or[0];
	my $sum;
	foreach my $i (1..$#or-1){
		$sum+=$or[$i];
	}
	foreach my $i (@order){
		if($or[$i] ne "R" and $or[$i] ne "S"){
			$or[$i] = $or[$i] eq "1" ? 1 : "NA";
			print "\t$or[$i]";
		}else{
			print "\t$or[$i]";
		}
	}
	my $pred= $sum > 0 ? "R" : "S";
	print "\t$pred\n";
}
close IN;

