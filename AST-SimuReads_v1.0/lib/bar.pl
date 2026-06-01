#!usr/bin/perl -w
use strict;

my ($in,$prefix)=@ARGV;
my $r="/data/GensKey/Work/gaojianpeng/work/Tools/Software/miniconda3/install/bin/R";
open R,">bar.r";
print R "library(ggplot2)
data<-read.table(\"$in\",head=T,sep=\"\\t\")
data\$sample<-factor(data\$sample,levels=unique(data\$sample))
rp<-ggplot(data=data,aes(x=sample,y=score,fill=ast))+geom_bar(stat=\"identity\",position=\"dodge\")+facet_wrap(~drug,scales=\"free\",ncol=4,labeller=labeller(class_drug=label_wrap_gen(30)))+coord_flip()+theme(strip.text=element_text(size=5),axis.text.x =element_text(size=5),axis.text.y=element_text(size=0.1))
ggsave(rp, filename = '$prefix.bar.pdf', width = 12, height = 12)
dev.off()\n";
close R;
system "$r -f bar.r 1>bar.log1 2>bar.log2";
