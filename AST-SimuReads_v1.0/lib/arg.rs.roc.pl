#!usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;
my ($tax,$shdir,$notrun,$outdir);
GetOptions("tax:s"=>\$tax,"shdir:s"=>\$shdir,"outdir:s"=>\$outdir,"notrun"=>\$notrun);
my ($in,$drug)=@ARGV;
-d $outdir || mkdir $outdir;
$outdir=abs_path($outdir);
-d $shdir || system "mkdir -p $shdir";
$shdir=abs_path($shdir);
$tax && ($tax =~ s/\s+/_/g);

my $focus="$Bin/focus_patho_drug.report";
my $predict="/data/Yixue/hanpeng/Software/conda_install/anaconda3/bin/python $Bin/roc.py ";
my $bar="perl $Bin/bar.pl ";
#my $paper="$Bin/drug.show.list.english";
my $ppvnpv="$Bin/ppv.npv.pl";
my $hpplot="perl $Bin/hp.ploy.scatter.pl"; #韩朋脚本，模型性能不佳药物选择两端Cutoff
my $super_worker="perl /data/Yixue/hanpeng/01.Product_tech/AMRdetect/00.Pipeline/AMRdetect_v1.3_NGS/lib/super_worker.pl --cyqt 1 --maxjob 900 --sleept 30 --resource 2G --splits \"\\n\\n\" ";
#----------------------------------------------------------------------
open IN,$focus;
<IN>;
my %focus_drug;
while(<IN>){
	chomp;
	my @or=split /\t/;
	my @arr=split /:/,$or[1];
	$arr[0]=~s/\s+|-/_/g;
	$arr[1]=~s/\s+|-/_/g;
	push @{$focus_drug{$or[0]}},"$arr[0]--$arr[1]";
}
close IN;
#------------------------------------------------------------------------
my %filter;
if($focus_drug{$tax}){
	foreach my $t (@{$focus_drug{$tax}}){
		$filter{$t}=1;
	}
	#print STDERR "#关注的药物包括:\n",join("\n",@{$focus_drug{$tax}}),"\n";
}else{
	die "ERROR!!!$tax 未在$focus文件中抓到 \n";
}
#------------------------------------------------------------------------
open IN,$drug;
my $one=<IN>;
chomp $one;
my @tt=split /\t/,$one;
my %rs;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$or[0]=~s/--/:/g;
	$or[0]=~s/-|\s+/_/g;
	$or[0]=~s/:/--/g;
	foreach my $j (1..$#or){
		if ($or[$j] eq "R" or $or[$j] eq "S"){
			$rs{$or[0]}{$tt[$j]}=$or[$j];
		}
	}
}
close IN;
#----------------------------------------------------
my %hash;
open IN,$in;
while(<IN>){
	chomp; # NS50_0.3_GCA_000401195.1_repeat_1   NS50_5_1284787.3_repeat_1
	my @arr=split /\t/;
	my @or=split /_/,$arr[0];
	my $gid;
	if ($arr[0]=~/GCA|GCF/){
		$gid=join("_",@or[2..3]);
	}else{
		$gid=$or[2];
	}
	my $platform=$or[0];
	my $depth=$or[1];
	open FF,$arr[1];
	<FF>;
	while(my $l=<FF>){
		chomp $l;
		my @arr=split /\t/,$l;
		$arr[0] =~ s/\s+/_/g;
		$arr[0] =~/$tax/ || next;
		my $drug=$arr[1];
#		my @tmp=split /:/,$drug;
#		$tmp[0]=~s/\s+|-/_/g;
#		$tmp[1]=~s/\s+|-/_/g;
		$drug=~s/\s+|-/_/g;
		$drug=~s/:/--/g;
#		$drug=join("--",@tmp);
		#print STDERR $drug,"\n";
#		if($rs{$drug}{$gid}){
#			print $platform,"\t",$depth,"\t",$drug,"\t",$gid,"\t",$arr[3],"\t",$rs{$drug}{$gid},"\n" if $rs{$drug}{$gid};
#		}
	
		push @{$hash{$platform}{$depth}{$drug}},$gid."\t".$drug."\t".$arr[3]."\t$rs{$drug}{$gid}\t$arr[2]" if $rs{$drug}{$gid};
	}
	close FF;	
}
close IN;
print "yes\n";

open SH,">$shdir/roc.sh";
foreach my $plat(sort keys %hash){
	foreach my $depth (sort keys %{$hash{$plat}}){
		foreach my $d (sort keys %{$hash{$plat}{$depth}}){
		#	print STDERR "###$plat\t$depth\t$d\n" and  next unless $filter{$d};
			$d=~s/\s+/_/g;
			my $dir="$outdir/$plat/$depth/$d";
			-d "$dir" || system "mkdir -p $dir";
			open OUT,">$dir/$d.input.xls";
			print OUT "sample\tdrug\tscore\tast\tfeatures\n";
			print OUT join("\n",@{$hash{$plat}{$depth}{$d}});
			close OUT;
			print SH "cd $dir
$predict -i $d.input.xls -p $d
$bar $d.input.xls $d
#$hpplot  $d.input.xls $d 
#less $d.cutoff.value |awk '\$10<0.1' |sort -nrk 8 |head -1 |cut -f 1 > $d.cutoff.value.sel  ##VME小于0.1且PPV最大
less $d.cutoff.value |grep Yes |cut -f 3 > $d.cutoff.value.sel
perl $ppvnpv $d.input.xls $d.cutoff.value.sel $d.process.txt  > $d.auc.ppv.npv\n\n";
		}
	}
}
close SH;

$notrun || system "cd $shdir;$super_worker --prefix roc roc.sh";
