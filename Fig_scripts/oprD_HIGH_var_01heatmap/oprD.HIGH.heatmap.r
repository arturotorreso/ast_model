library(pheatmap)
###################################  IPM  #########################################
setwd("D://R/projects/Genskey/RJ_PA_resistantance_prediction/20230330oprD_HIGH_var_01heatmap/IPM/")
x<-read.table("total.var.new.level.samsort2.rename2.filter.sort.xls",sep="\t",header=T,row.names=1)
group<-read.table("ipm.sort2",sep="\t",header=F)
group2<-read.table("feature.group2",sep="\t",header=F)
annotation_col = data.frame(AST=factor(group$V2),Dataset=factor(group$V3))
annotation_row = data.frame(Present_type=factor(group2$V2))
rownames(annotation_col) = group$V1
rownames(annotation_row) = group2$V1
ann_colors=list(AST=c("R"="#DB7093","S"="#87CEEB"),
                Dataset=c("Tr"="#696969","Va"="#BC8F8F"),
                Present_type=c("In_Tr"="#696969","In_Tr_Va"="#1E90FF","In_Va"="#BC8F8F"))
pdf(file="IPM.pdf",width=7,height=7)
h<-pheatmap(x,scale="none",cluster_cols=F,cluster_rows=F,
            display_numbers =F, angle_col = "45",
            annotation_col=annotation_col,annotation_colors=ann_colors,
            color = colorRampPalette(c("white","#000080"))(50),
            show_colnames=FALSE,show_rownames=T,cellheight=3.5,fontsize=3.45,
            annotation_row=annotation_row,gaps_row=c(1),
            cellwidth=0.45,legend=F) 
dev.off()

###################################  MEM  #########################################
setwd("D://R/projects/Genskey/RJ_PA_resistantance_prediction/20230330oprD_HIGH_var_01heatmap/MEM/")
x<-read.table("total.var.new.level.samsort2.rename2.filter.sort.xls",sep="\t",header=T,row.names=1)
group<-read.table("mem.sort2",sep="\t",header=F)
group2<-read.table("feature.group2",sep="\t",header=F)
annotation_col = data.frame(AST=factor(group$V2),Dataset=factor(group$V3))
annotation_row = data.frame(Present_type=factor(group2$V2))
rownames(annotation_col) = group$V1
rownames(annotation_row) = group2$V1
ann_colors=list(AST=c("R"="#DB7093","S"="#87CEEB"),
                Dataset=c("Tr"="#696969","Va"="#BC8F8F"),
                Present_type=c("In_Tr"="#696969","In_Tr_Va"="#1E90FF","In_Va"="#BC8F8F"))
pdf(file="MEM.pdf",width=8,height=8)
h<-pheatmap(x,scale="none",cluster_cols=F,cluster_rows=F,
            display_numbers =F, angle_col = "45",
            annotation_col=annotation_col,annotation_colors=ann_colors,
            color = colorRampPalette(c("white","#000080"))(50),
            show_colnames=FALSE,show_rownames=T,cellheight=3.2,fontsize=3.15,
            annotation_row=annotation_row,gaps_row=c(1),
            cellwidth=0.34,legend=F) 
dev.off()


