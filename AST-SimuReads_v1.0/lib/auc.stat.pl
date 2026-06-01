#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);
my ($in)=@ARGV;

my %hash;
my $drug_class_file="$Bin/drug_class.xls";
open IN,$drug_class_file;
<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	my $class_eng=$or[-3];
	$class_eng=~s/\s+/_/g;
	$class_eng=~s/-/_/g;
	my $drug_eng=$or[-2];
	$drug_eng=~s/\s+/_/g;
	$drug_eng=~s/-/_/g;
	my $class_chi=$or[2];
	my $drug_chi=$or[-1];
	$hash{"$class_eng:$drug_eng"}="$class_chi:$drug_chi";
}
close IN;

my %auc;
open IN,$in;
my %drugs;
my %depth;
my %plats;
while(<IN>){
	chomp;
	my @or=split /\//;
	my @dd=split /--/,$or[-2];
	$dd[1]=~s/-/_/g;
	$dd[0]=~s/-/_/g;
	my $chi=$hash{"$dd[0]:$dd[1]"} ? "$dd[0]:$dd[1](".$hash{"$dd[0]:$dd[1]"}.")" : "-";
	$drugs{$chi}=1;
	my $plat=$or[-3];
	$plats{$plat}=1;
	open FF,$_;
	<FF>;
	while(my $l=<FF>){
		chomp $l;
		my @arr=split /\t/,$l;
		$auc{$plat}{$chi}{"$arr[0]:$arr[1]"}=$arr[-1];
		$depth{$arr[0]}="$arr[0]:$arr[1]";
	}
	close FF;
}
close IN;

my @plat=sort keys %plats;
my @depth=sort {$a <=> $b} keys %depth;
my @drugs=sort keys %drugs;

print "Platform\tDepth\t",join("\t",@drugs),"\n";
foreach my $i (@plat){
	foreach my $d (@depth){
		print $i,"\t",$depth{$d};
		foreach my $g (@drugs){
			$auc{$i}{$g}{$depth{$d}}||="-";
			print "\t",$auc{$i}{$g}{$depth{$d}};
		}
		print "\n";
	}
}
