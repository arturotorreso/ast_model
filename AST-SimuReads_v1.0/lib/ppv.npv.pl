#!usr/bin/perl -w
use strict;

my ($input,$cutoff,$auc)=@ARGV;

open IN,$auc;
my $line1=<IN>;
chomp $line1;
my @arr=split /\t/,$line1;
my $auc_value=$arr[-1];

#my $cut=`cat $cutoff|grep Yes |cut -f 1`;
my $cut=`cat $cutoff`;
chomp $cut;
$cut||die $!;

my %truep;
my %truen;
my %values;
open IN,$input;
<IN>;
while(<IN>){
    chomp;
    my @or=split /\t/;
    if($or[-2] eq "R"){
        $truep{$or[0]}=1;
    }elsif($or[-2] eq "S"){
        $truen{$or[0]}=1;
    }else{
        next;
    }   
}
close IN;

open IN,$input;
<IN>;
my %predp;
my %predn;
while(<IN>){
    chomp;
    my @or=split /\t/;
	if($or[2] >= $cut){
    	$predp{$or[0]}=1;
	}else{
        $predn{$or[0]}=1;
    }
}
close IN;

my $predp=scalar keys %predp;
my $predn=scalar keys %predn;

my $fp=0;
my $tp=0;
if( %predp){
	foreach my $g (sort keys %predp){
    	if($truep{$g}){
			$tp++;
		}else{
			$fp++;
		}
	}
}

my $fn=0;
my $tn=0;
if(%predn){
	foreach my $g (sort keys %predn){
		if($truen{$g}){
			$tn++;
		}else{
			$fn++;
		}
	}
}

my $ppv;
my $ppvstr;
if ($tp+$fp >0){
	$ppv=$tp/($tp+$fp);
	$ppvstr="$tp/($tp+$fp)";
}else{
	$ppv="NA";
	$ppvstr="-";
}
my $npv;
my $npvstr;
if($tn+$fn>0){
	$npv=$tn/($tn+$fn);
	$npvstr="$tn/($tn+$fn)";
}else{
	$npv="NA";
	$npvstr="-";
}
print "#Cutoff\tPPV\tNPV\tAUC\n";
print $cut,"\t","$ppvstr:".$ppv,"\t","$npvstr:".$npv,"\t",$auc_value,"\n";
