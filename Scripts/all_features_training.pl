#!usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

sub usage
{
        print STDERR <<USAGE;
=========================================================================
		#Description：基于Pisces变异检测结果进行机器学习（LASSO)进行耐药特征挖掘,增加整合CARD特征的接口,增加drugclass对变异基因的限制
		#Date: 20220712
		#Version: v3  
		#Email: gjpbioinfo\@163.com
Options
		-in <s> :   file 
		-ast <s> : AST药敏数据
		-output<s> :    the output directory
		-identity_cutoff <f> : 相似性阈值
		-shdir <s> :	shdir 
		-ppv_cutoff <f>:  训练PPV阈值
		-gn_cutoff <i> :   真阳性基因组数目阈值
		-tax <s> : 待分析物种名称，用于绘制特征热图
		-del_efflux 是否去掉外排泵机制基因进行训练，默认不去
		-h|?|help   :  Show this help
		-notrun		:   print shell 
=========================================================================
USAGE
}

my ($in,$ast,$outdir,$shdir, $help,$prefix,$ppv_cutoff,$gn_cutoff,$del_efflux,$tax,$identity_cutoff,$gpafile);
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
		"gpa:s"=>\$gpafile,
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
my $super="perl $Bin/super_worker.pl --prefix run  --cyqt 1 --maxjob 200 --sleept 30 --resource 2G --splits \"\\n\\n\"  ";

$tax||="Pseudomonas aeruginosa";
$ppv_cutoff||=0.8;
$gn_cutoff||=1;
#################################### 主脚本  ###############################

my %gpafile;
if ($gpafile && -s $gpafile){
	open IN,$gpafile;
	while(<IN>){
		chomp;
		my @or=split /\t/;
		$gpafile{$or[0]}=$or[1];
	}
	close IN;
}

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
	next unless $gpafile{$or[0]};
	print SH "cd $outdir/$drugclass/$drug
perl $Bin/lib/merge.var.ast.pl $in sample.ast.list $drugclass > traininginput.raw0.xls  2>filter.log\n";
	if ($gpafile && -s $gpafile){
		print SH "perl $Bin/lib/merge.features.pl traininginput.raw0.xls $gpafile{$or[0]} > traininginput.raw.xls\n";
	}
	print SH "[[ ! -s traininginput.raw.xls  ]]  && ln -s traininginput.raw0.xls traininginput.raw.xls
perl $Bin/lib/ppv.npv.filter.pl traininginput.raw.xls --ppv_cutoff $ppv_cutoff --tp_genome_cutoff $gn_cutoff > training.filtered.xls  2> training.filtered.log
grep -v \"#\"  training.filtered.xls |cut -f 1 > training.filtered.id
echo \"ARG\" >> training.filtered.id
echo \"AST\" >> training.filtered.id
perl $Bin/lib/sel.sample.pl training.filtered.id  traininginput.raw.xls > lasso.input.xls
perl $Bin/rgi_lasso_training_pipeline/lib/lm.pl lasso.input.xls lasso_v1 --cutoff 1000  --outdir lasso_v1_output
#--------------------------------------------------------------------------------------------------------------
perl $Bin/lib/sel.keyfeatures.pl  lasso_v1_score.xls traininginput.raw.xls > lasso_v1_score.table.xls
perl $Bin/lib/reorder.v2.pl lasso_v1_score.xls lasso_v1_score.table.xls > lasso_v1_score.table.sort1.xls
perl $Bin/lib/sort.art.table.pl lasso_v1_score.table.sort1.xls > lasso_v1_score.table.sort2.xls
perl $Bin/lib/heatmap.svg.pl lasso_v1_score.table.sort2.xls --taxname \"$tax\" --drug \"$drugclass:$drug\" lasso_v1_score.heatmap.svg
$Bin/rgi_lasso_training_pipeline/lib/svg2xxx_release/svg2xxx -t png -dpi 900 lasso_v1_score.heatmap.svg
perl $Bin/lib/tableformat.pl lasso_v1_score.table.xls lasso_v1_score.xls $drugclass--$drug > lasso_v1_score.roc.input.xls
/home/L1/gaojianpeng/software/miniconda3/bin/python $Bin/../../rgi_lasso_training_pipeline/lib/roc.py -i lasso_v1_score.roc.input.xls -p lasso_v1_score.roc\n\n";
}
close IN;
close SH;

system "cd $shdir;$super step2.LassoTraining.sh";
	
#################################### 子函数  ###############################
