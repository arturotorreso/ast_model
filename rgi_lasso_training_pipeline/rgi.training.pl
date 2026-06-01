#!usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

my ($in,$ast,$outdir,$shdir, $help,$prefix,$ppv_cutoff,$gn_cutoff,$del_efflux,$tax,$identity_cutoff);
GetOptions(
        "in=s"=>\$in,
        "ast=s"=>\$ast,
		"ppv_cutoff:s"=>\$ppv_cutoff,
		"gn_cutoff:i"=>\$gn_cutoff,
        "outdir=s"=>\$outdir,
		"shdir=s"=>\$shdir,
		"tax:s"=>\$tax,
		"identity_cutoff:s"=>\$identity_cutoff,
		"del_efflux"=>\$del_efflux,
        "h|?|help"=>\$help
);
if(!defined($in) || defined($help)) {
        &usage;
        exit 0;
}

#################################### 变量声明及调用文件 ####################
$in=abs_path($in);
$ast=abs_path($ast);
$outdir||=".";
-d $outdir || mkdir $outdir;
$outdir=abs_path($outdir);
-d $shdir || mkdir $shdir;
$shdir =abs_path($shdir);

$tax||="Pseudomonas aeruginosa";
$ppv_cutoff||=0.8;
$gn_cutoff||=1;
$del_efflux =$del_efflux ? "del_efflux" : "";
$identity_cutoff||=80;
#################################### 主脚本  ###############################

open IN,$ast;
my $line=<IN>;
chomp $line;
my @title=split /\t/,$line;
open SH,">$shdir/step2.LassoTraining.sh";
while(<IN>){
	chomp;
	my @or=split /\t/;
	my ($drugclass,$drug)=split /--/,$or[0];
	-d "$outdir/$drugclass/$drug" || system "mkdir -p $outdir/$drugclass/$drug";
	open OUT,">$outdir/$drugclass/$drug/sample.ast.list";
	foreach my $i (1..$#or){
		print OUT $title[$i],"\t",$or[$i],"\n";
	}
	close OUT;
	
	print SH "cd $outdir/$drugclass/$drug
perl $Bin/lib/merge.aro.ast.gf.variation.subfamily.pl $in sample.ast.list  $drugclass $del_efflux > traininginput.raw.xls  --identity_cutoff $identity_cutoff 2>filter.log
perl $Bin/lib/ppv.npv.filter.pl traininginput.raw.xls --ppv_cutoff $ppv_cutoff --tp_genome_cutoff $gn_cutoff > training.filtered.xls  2> training.filtered.log
grep -v \"#\"  training.filtered.xls |cut -f 1 > training.filtered.id
echo \"ARG\" >> training.filtered.id
echo \"AST\" >> training.filtered.id
perl $Bin/lib/sel.sample.pl training.filtered.id  traininginput.raw.xls > lasso.input.xls
perl $Bin/lib/lm.pl lasso.input.xls lasso_v1 --cutoff 1000  --outdir lasso_v1_output
#--------------------------------------------------------------------------------------------------------------
perl $Bin/lib/sel.keyfeatures.pl  lasso_v1_score.xls traininginput.raw.xls > lasso_v1_score.table.xls
perl $Bin/lib/reorder.v2.pl lasso_v1_score.xls lasso_v1_score.table.xls > lasso_v1_score.table.sort1.xls
perl $Bin/lib/sort.art.table.pl lasso_v1_score.table.sort1.xls > lasso_v1_score.table.sort2.xls
perl $Bin/lib/heatmap.svg.pl lasso_v1_score.table.sort2.xls --taxname \"$tax\" --drug \"$drugclass:$drug\" lasso_v1_score.heatmap.svg
$Bin/lib/svg2xxx_release/svg2xxx -t png -dpi 900 lasso_v1_score.heatmap.svg
perl $Bin/lib/tableformat.pl lasso_v1_score.table.xls lasso_v1_score.xls $drugclass--$drug > lasso_v1_score.roc.input.xls
/home/L1/gaojianpeng/software/miniconda3/bin/python $Bin/lib/roc.py -i lasso_v1_score.roc.input.xls -p lasso_v1_score.roc\n\n";
}
close IN;
close SH;
	
	
#################################### 子函数  ###############################
