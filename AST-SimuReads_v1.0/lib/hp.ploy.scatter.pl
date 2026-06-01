#!usr/bin/perl  -w
use strict;
use FindBin qw($Bin);

my ($input,$prefix)=@ARGV;

my%hash;
my %info;
open  IN,$input;
my $one=<IN>;
while(<IN>){
	chomp;
	my @or=split /\t/;
	$hash{$or[0]}=$or[2];
	$info{$or[0]}=$_;
}
close IN;

open OUT,">$prefix.sort.input.xls";
print OUT $one;
foreach my $g (sort {$hash{$a} <=> $hash{$b}} keys %hash){
	print OUT $info{$g},"\n";
}
close OUT;

my $scatter=<< "EOF";
library(ggplot2)
data<-read.table("$prefix.sort.input.xls",h=T,sep="\\t")
aa<-unique(data\$sample)
data\$sample<-factor(data\$sample,levels=aa)
pdf("$prefix.score.pdf",width=10,height=8)
ggplot(data,aes(y=sample,x=score,colour=ast))+geom_point()+theme(axis.title = element_text(color="black",size=10),axis.ticks = element_line(color="black"),axis.title.x = element_text(colour="black",size=10),axis.title.y = element_text(colour="black",size=0),axis.text.y= element_text(angle=45,hjust=1,size=1),,axis.text.x= element_text(angle=45,hjust=1),axis.line = element_line(colour = "black"))
#+geom_vline(xintercept =c(3.36595479438531,5.53143240923515),lty=2)
dev.off()

EOF


open OUT,">$prefix.scatter.r";
print OUT $scatter;
close OUT;

system "/data/GensKey/Work/gaojianpeng/work/Tools/Software/miniconda3/install/bin/R -f $prefix.scatter.r";
#--------------------------------------------------------------------------------------------

open  SH,">polyline.sh";
print  SH "
perl $Bin/stat_performance.pl $input > $prefix.input.stat.xls  2> $prefix.stat_cutoff.xls
perl -ne 'BEGIN{print \"ID\\tValue\\titem\\n\";} /^ID/ && next;chomp;\@ll=split /\\t/;print \"\$ll[0]\\t\$ll[3]\\tSensitivity\\n\$ll[0]\\t\$ll[4]\\tSpecifity\\n\$ll[0]\\t\$ll[5]\\tPPV\\n\$ll[0]\t\$ll[6]\\tNPV\\n\$ll[0]\\t\$ll[10]\\tDiscard_rate\\n\"; ' $prefix.input.stat.xls > $prefix.stat.plot.xls\n";
close SH;

system  "sh polyline.sh";

my $ployline=<< "EOF";
library(ggplot2)
data<-read.table("$prefix.stat.plot.xls",h=T,sep="\\t")
data\$item <- factor(data\$item,levels=c("Sensitivity","Specifity","PPV","NPV","Discard_rate"))
pdf("$prefix.cutoff.pdf",width=10,height=8)
ggplot(data=data,aes(x=ID,y=Value,colour=item))+geom_line()+geom_hline(yintercept=0.9,lty=2)
#+ geom_vline(xintercept=11,lty=2)+ geom_hline(yintercept=0.9,lty=2)
dev.off()

EOF

open OUT,">$prefix.ployline.r";
print OUT $ployline;
close OUT;

system  "/data/GensKey/Work/gaojianpeng/work/Tools/Software/miniconda3/install/bin/R -f $prefix.ployline.r";
