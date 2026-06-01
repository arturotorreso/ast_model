library(pheatmap)
library(export)
setwd("D://R/projects/RJ_PA_resistantance_prediction/20230330genome_level_AUC_heatmap/")
x<-read.table("merge.auc2.xls",sep="\t",header=T,row.names=1)
pdf(file="auc.heatmap.pdf",width=5,height=5)
#png(file="auc.heatmap.png",width=3,height=2,res=100)
h<-pheatmap(t(x),scale="none",cluster_cols=F,
         cluster_rows=F,display_numbers =T,
         cellwidth=28,cellheight=20, angle_col = "90",
         fontsize=12,gaps_row=c(1),gaps_col=c(1,3),
         color = colorRampPalette(c("white","firebrick3"))(100),
         legend_breaks=c(0.8,0.84,0.88,0.92),
         number_format="%.3f",
        )
graph2ppt(h,file="auc.heatmap.pptx", width=5, height=5)
dev.off()