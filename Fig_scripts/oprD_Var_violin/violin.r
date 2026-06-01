

library(ggpubr)
setwd("D://R/projects/RJ_PA_resistantance_prediction/20230330violin/")
#IPM
data<-read.table("ipm.fig.input.xls",sep="\t",header=T)
fig<-  ggviolin(data, x="Impact", y="PPV" , color = "Impact",
                trim=TRUE,
                size=0.1, 
                palette = c('lancet'), 
                add = c("mean_sd"),
                order=c("HIGH","MODERATE","LOW"))+
  labs(title="",x="",y="PPV")+ 
  theme(legend.title=element_blank(),
        legend.text=element_text(size=20),
        axis.text = element_text(size=20),
        axis.title = element_text(size=20))+
  geom_hline(aes(yintercept=0.9), colour="gray", linetype="dashed")+ 
  scale_y_continuous(limits=c(0,1.2), breaks=seq(0,1.2,0.2))+ #刻度控制
  geom_jitter(width=0.13,aes(color=Impact,size=Size,alpha=Size)) 

ggsave(fig,filename ='oprd.IPM.violoin.pdf',width=8.5,height=5)
ggsave(fig,filename ='oprd.IPM.violoin.png',width=8.5,height=5)

#IPM
data<-read.table("mem.fig.input.xls",sep="\t",header=T)
fig<-  ggviolin(data, x="Impact", y="PPV" , color = "Impact",
                trim=TRUE,
                size=0.1, 
                palette = c('lancet'), 
                add = c("mean_sd"),
                order=c("HIGH","MODERATE","LOW"))+
  labs(title="",x="",y="PPV")+ 
  theme(legend.title=element_blank(),
        legend.text=element_text(size=20),
        axis.text = element_text(size=20),
        axis.title = element_text(size=20))+
  geom_hline(aes(yintercept=0.9), colour="gray", linetype="dashed")+ 
  scale_y_continuous(limits=c(0,1.2), breaks=seq(0,1.2,0.2))+ #刻度控制
  geom_jitter(width=0.13,aes(color=Impact,size=Size,alpha=Size)) 

ggsave(fig,filename ='oprd.MEM.violoin.pdf',width=8.5,height=5)
ggsave(fig,filename ='oprd.MEM.violoin.png',width=8.5,height=5)