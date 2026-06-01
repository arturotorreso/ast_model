#!usr/bin/perl -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
#my $identity_cutoff;
#GetOptions("identity_cutoff:s"=>\$identity_cutoff);
my ($in,$samplelist,$drugclass)=@ARGV;
#Description：基于变异特征进行耐药特征挖掘
#Date: 20220224
#Version: v0.1
#Email: gjpbioinfo\@163.com

open IN,"$Bin/arg.drug";
my %check;
while(<IN>){
	chomp;
	my @or=split /\t/;
#	my @arr=split /,/,$or[1];
	next if $_=~/#/;
	foreach my $g (@or[1..$#or]){
		$check{$or[0]}{$g}=1;
	}
}
close IN;

my %ast;
open IN,$samplelist;
while(<IN>){
	chomp;
	my @or=split /\t/;
	next if $or[1] ne "R" and  $or[1] ne "S";
	$ast{$or[0]}=$or[1];
}
close IN;

my @features;
my %hash;
open IN,$in;
my $title=<IN>;
chomp $title;
my @tt=split /\t/,$title;
while(<IN>){
	chomp;
	my @or=split /\t/;
	my @jj=split /\(/,$or[0];
	#next unless $check{$drugclass}{$jj[0]};
	push @features,$or[0];
	foreach my $i (0..$#or){
		$hash{$tt[$i]}{$or[0]}=$or[$i];
	}
}
close IN;

print "AST\tARG\t",join("\t",@features),"\n";
foreach my $sam (sort {$ast{$a} cmp $ast{$b}} keys %ast){
	print "$ast{$sam}\t$sam";
	foreach my $f (@features){
		$hash{$sam}{$f}||="0";
		print "\t$hash{$sam}{$f}";
	}
	print "\n";
}
