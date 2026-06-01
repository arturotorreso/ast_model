#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my $cutoff; ###R/S或者S/R倍数
GetOptions("cutoff:i"=>\$cutoff);
$cutoff ||=10;
##########################
my $r="/home/L1/gaojianpeng/software/miniconda3/bin/Rscript";
my $lasso="$Bin/lasso.main.v1.0.R";
my $trans="$Bin/Tran_table.pl";
my $filter0="$Bin/filter0.pl";
#20210104 优化模型 https://blog.csdn.net/orchidzouqr/article/details/53582801
#20210110 LASS回归优化
my ($in,$drug)=@ARGV;
system "perl $trans $in > lm.tmp.trans.xls";
system "perl $filter0 lm.tmp.trans.xls > lm.tmp.trans.filter0.xls";
system "perl $trans lm.tmp.trans.filter0.xls > lm.input.xls";
##############################################################################
open IN,"lm.input.xls";
my $one=<IN>;
chomp $one;
my @title=split /\t/,$one;
my $bianliang_number=(scalar @title)-2;
my %name;
my @arr;
open OUT,">tmp.xls";
foreach my $n (@title[2..$#title]){
	my $new=$n;
	$new=~s/[\[\]\(\)'-]/_/g;
	$new=~s/\:/_/g;
	$new=~s/\//_/g;
	$new=~s/\s+/_/g;
	$new=~s/>/_/g;
	if($new=~/^[1-9]/){
		$new="X".$new;
	}
	$name{$new}=$n;
	push @arr,$new;
}
my $fun=join("+",@arr);
print OUT join("\t",@title[0..1]),"\t",join("\t",@arr),"\n";
my $rn=0;
my $sn=0;
while(<IN>){
	print OUT $_;
	my @or=split /\t/;
	$sn++ if $or[0] eq "S";
	$rn++ if $or[0] eq "R";
}
close OUT;

if($rn==0 or $sn==0  or $rn/$sn>$cutoff or $sn/$rn >$cutoff or $bianliang_number <2){
	open ERR,">lm.err.log";
	print ERR "S:$rn R:$sn 抗性基因（变量）个数：$bianliang_number SR样本不足或数量差异过大或变量数目过少，停止分析!\n";
	close ERR;
	die "S:$rn R:$sn SR样本不足或数量差异过大，停止分析!\n";
}

#open OUT,">runlm.r";
#print OUT "library(MASS)
#library(glmnet)
#data<-read.table(\"tmp.xls\",head=T,row.names=2,sep=\"\\t\",check.names=F,quote=\"\")
#tmp.y<-data\$AST
#tmp.x<-as.matrix(data[,2:length(data)])
#cv.model<-cv.glmnet(tmp.x,tmp.y,family=\"binomial\",nlambda=50,alpha=1,standardize=T)
#coefficients<-coef(cv.model,s=cv.model\$lambda.min)
#select<-c()
#for(i in 1:length(coefficients)){ifelse(coefficients[i] != \".\",select<-c(select,coefficients[i]),next)}
#names<-c()
#for(i in 1:length(coefficients)){ifelse(coefficients[i] != \".\",names<-c(names,row.names(coefficients)[i]),next)}
#names(select)<-names
#multi <- paste(names[2:length(names)],collapse =\" + \")
#formula <- paste(\"AST\",multi,sep=\" ~ \")
#fit<-glm(formula,data=data,family=binomial())
#fit.sel<-stepAIC(fit)
#write.table(coef(fit.sel),file=\"lmout.xls\",quote=F,sep=\"\\t\")\n";
#close OUT;
#system "$r -f runlm.r 1>runlm.log1 2>runlm.log2";
system "$r $lasso --infile tmp.xls --outdir lasso.output 1>lasso.log 2>lasso.err.log";
open IN,"lasso.output/keygene-coef.min_errcv.xls";
open OUT,">$drug\_score.xls";
my %values;
<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$values{$or[2]}=$or[3] if ($or[3] ne "NA" and $or[3]>0); #2021 部分变量为NA
}
close IN;
##
foreach my $k (sort {$values{$b} <=> $values{$a}} keys %values){
	print OUT $name{$k},"\t",$values{$k},"\n";
}
close OUT;
