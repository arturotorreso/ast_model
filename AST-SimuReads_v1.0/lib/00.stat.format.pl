#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);
my ($stat,$coverage,$platform,$tax)=@ARGV;
#将比对出来的ARGs进行文件的格式转换，对接score计算及AST预测的脚本；如果前面未进行coverage的计算的话coverage给100

my $db="$Bin/DB.tax.format";
$tax=~s/_/ /g;
my %gid2tax;
open IN,$db;
<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$gid2tax{$or[0]}=$or[5];
}
close IN;

my %cov;
my $coverage_value;
if ($coverage && -s $coverage ){
	if ($platform=~/NS50/){
		open IN,$coverage ||die $!;
		<IN>;
		while(<IN>){
			chomp;
			my @or=split /\t/;
			#taxid   coverage        depth   identity        uniq_bins       multi_bins      genomeid
			#573     16.049143%(911964/5682322)      1.10    100.00  98      0       GCA_000240185.2
			unless ($gid2tax{$or[-1]}){
				print STDERR "!!! 警告 $or[-1]的物种拉丁文未抓到!\n";
				die $!;
			}
			my @arr=split /\%/,$or[1];
			$cov{$gid2tax{$or[-1]}}=$arr[0];
		}
		close IN;
	}elsif($platform=~/ONT/){
		open IN,$coverage ||die $!;		
		while(<IN>){
			chomp;
			my @or=split /\t/;
			#Escherichia coli        GCF_000008865.2 1776/5594605    0.032   1.0
			#Klebsiella pneumoniae   GCF_000240185.1 939310/5682322  16.530  1.1
			$cov{$or[0]}=$or[-2];
		}
		close IN;
	}else{
		die "!!!平台未匹配成功,请核对";
	}
	if($cov{$tax}){
		$coverage_value=$cov{$tax};
	}else{
		$coverage_value="100";
	#	die "!!! $tax 的覆盖度信息未抓到!\n";
	}
}else{
	$coverage_value="100";
}
#--------------------   -------   ---------------------
my %hash;
open IN,$stat;
<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	next if $or[17] eq "NA";
	my @class=split /;/,$or[17]; #drug class
	foreach my $c (@class){
		push @{$hash{$c}},"$or[0]($or[1])--$or[2]($or[3])--$or[4]($or[5]|1)--A"; # L4_arg_family L4_rn L3_arg_subfamily	L3_rn	L1_aro_name	L1_rn
	}
}
close IN;

print "#focus_patho\tdrug_class\tdetect_ARGs\tgenome_coverage\tAvgDepth\tspe_rn\tgenus_rn\ttotal_Bac_rn\n";
foreach my $c (sort keys %hash){
	print "$tax\t$c\t",join(";",@{$hash{$c}}),"\t$coverage_value\t9999999\t9999999\t99999999\n";
}
