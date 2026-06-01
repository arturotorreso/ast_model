library(ggplot2)
library(ggpubr)
data<-read.table("D://R/projects/20230223PApaopao/merge.xls",
                 head=T,sep="\t")
#my_cols<-c("#A9A9A9","#808080","#D2691E","#696969","#000080","#DC143C")
my_cols<-c("black","#D3D3D3","#DC143C")
fig<-ggballoonplot(data, x = "IPM.Impact", y = "Gene", size = "Size",color ="black",
                   fill = "PPV")+
  scale_fill_gradientn(colors = my_cols)+
  theme(legend.title=element_blank(),
        legend.text=element_text(size=18),
        axis.text = element_text(size=18),
        axis.title = element_text(size=18))
ggsave(fig,filename ='D://R/projects/20230223PApaopao/pao.pdf',width=8,height=8)