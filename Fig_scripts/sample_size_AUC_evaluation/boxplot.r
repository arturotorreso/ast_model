library(ggplot2)
setwd("D://R/projects/RJ_PA_resistantance_prediction/20230309sample_size_AUC_evaluation/")
data<-read.table("carbapenem--imipenem.boxplot.input2.xls",head=T,sep="\t")
bar<-ggplot(data, aes(x=factor(GenomesNumber,
                               level=c("107","214","322","429","538","645"),
                               ordered = TRUE),y=AUC))+
  geom_boxplot(aes(fill = DataSet), notch = FALSE, size =0.3,
               outlier.size=0,outlier.alpha=0) +
  scale_fill_manual(values=c("#FF4500")) +
  theme_bw()+labs(title="IPM", x='Sample Size', y='AUC')+
  scale_y_continuous(limits=c(50,100), breaks=seq(50,100,10))+ 
  theme(plot.title = element_text(hjust = 0.5,size=25), 
        axis.text.x=element_text(size=18),axis.text.y=element_text(size=18),
        axis.title.y=element_text(size=25),axis.title.x=element_text(size=25))+
  guides(fill=F)
ggsave(bar,filename ='IPM.samplesize.auc.boxplot.pdf',width=7,height=4)
ggsave(bar,filename ='IPM.samplesize.auc.boxplot.png',width=7,height=4)


data<-read.table("carbapenem--meropenem.boxplot.input2.xls",head=T,sep="\t")
bar<-ggplot(data, aes(x=factor(GenomesNumber,level=c("172","346","520","694","868","1041"),
                               ordered = TRUE),y=AUC)) +
  geom_boxplot(aes(fill = DataSet), notch = FALSE, size =0.3,outlier.size=0,outlier.alpha=0) +
  scale_fill_manual(values=c("#FF4500")) +
  theme_bw()+labs(title="MEM", x='Sample Size', y='AUC')+
  scale_y_continuous(limits=c(50,100), breaks=seq(50,100,10))+
  theme(plot.title = element_text(hjust = 0.5,size=25), 
        axis.text.x=element_text(size=18),
        axis.text.y=element_text(size=18),
        axis.title.y=element_text(size=25),
        axis.title.x=element_text(size=25))+
  guides(fill=F)
ggsave(bar,filename ='MEM.samplesize.auc.boxplot.pdf',width=7,height=4)
ggsave(bar,filename ='MEM.samplesize.auc.boxplot.png',width=7,height=4)
