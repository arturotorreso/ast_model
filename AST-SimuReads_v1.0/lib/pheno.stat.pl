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
#---------------------------------------------------------------------
open IN,$in;
print "Class_Drug\tAST_total_n\tAST_R\tAST_S\tAST_I\tAST_SDD\tND\n";
while(<IN>){
	chomp;
	/^Drug/ && next;
	my @ll=split /\t/;
	my %num=();
	for my $i(1..$#ll){
		$ll[$i]=~s/\]$//;
		$num{$ll[$i]}++;
		if($ll[$i] ne "NA"){
			$num{"AST_total_n"}++;
		}
	}
	$ll[0]=~s/--/:/g;
	$ll[0]=~s/-/_/g;
	$ll[0]=~s/\s+/_/g;
	my $chi= $hash{$ll[0]} ? $hash{$ll[0]} : "-";
	print "$ll[0]($chi)";
	for my $type(qw/AST_total_n R S I SDD NA/){
		$num{$type} ||= 0;
		print "\t$num{$type}";
	} 
	print "\n";
}
close IN;
	
	
