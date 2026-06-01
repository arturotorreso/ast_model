suppressPackageStartupMessages(library("optparse"))

option_list <- list(
        make_option("--infile", action="store",default=NULL, help="The dirctory of Evenabs.mat, look like: result.txt: group_names\tvar1\tvar2...varn"),
        make_option("--outdir", action="store",default="./", help="The output dirctory,  [default %default]"),
        make_option("--headvar", action="store", type="integer", default=100,  help="The important variables to use in randomForest to show in the picture,  [default %default]")
)

opt<-parse_args(OptionParser(usage="%prog [options] file\n", option_list=option_list))
if(is.null(opt$infile)){
    cat ("Use  %prog -h for more help info\nThe author: hanpeng\n")
    quit("no")
}

infile<-opt$infile
outdir<-paste(opt$outdir,"/",sep="")
if(!file.exists(outdir)){
    dir.create(outdir)
}

library(glmnet)
library(pROC)
library(ggplot2)
set.seed(999)
source("/home/L1/gaojianpeng/projects/pa_ast/analyse/JCM/scripts/rgi_lasso_training_pipeline/lib/lasso.crossvalidation.r")
c_table <- read.table(infile,sep="\t",header=T,row.names=2,check.names=F,quote="")
cv.fold=10
repeattimes = 5
c_table <- data.frame(c_table)
table.split <- sample(c(1,2), nrow(c_table), replace = TRUE, prob=c(0.8,0.2))  #样本数一定要大
trainset <- c_table[table.split == 1,]
testset <- c_table[table.split == 2,]

trainset_outfile <- paste(outdir,"/","trainset.ori.xls",sep="")
testset_outfile <- paste(outdir,"/","testset.xls",sep="")
write.table(trainset,trainset_outfile,sep="\t")
write.table(testset,testset_outfile,sep="\t")
table(trainset[,1]);table(testset[,1])
train_X<-trainset[2:ncol(trainset)]
train_Y<-trainset[,1]

X = model.matrix(AST ~ ., data = c_table)
Y = factor(c_table[,1],levels=c("S","R"))
result <- replicate(repeattimes, lasso.cv(X,Y , cv.fold=cv.fold), simplify=FALSE) 

###计算不同基因数目下的AUC均值
AUC <- sapply(result, "[[", "AUC") #
auc2 <- cbind(rowMeans(AUC), apply(AUC,1,sd), AUC)
colnames(auc2) <- c("mean", "sd", paste("r",c(1:dim(AUC)[2]),sep=""))
#write.table(auc2,paste(outdir,"/","varnum-auc.xls",sep=""), sep="\t",quote=F)

###计算不同基因数目下的分类错误均值
error.cv <- sapply(result, "[[", "error.cv") #
error.cv2 <- cbind(rowMeans(error.cv), apply(error.cv,1,sd), error.cv)
colnames(error.cv2) <- c("mean", "sd", paste("r",c(1:dim(error.cv)[2]),sep=""))
#write.table(error.cv2,paste(outdir,"/","varnum-error.xls",sep=""), sep="\t",quote=F)

#error.cv2 <- data.frame(top_gene_num=rownames(error.cv),auc=error_mean)
#       [,1]      [,2]      [,3]      [,4]      [,5]#repeattimes
#99 0.3157895 0.2456140 0.2456140 0.2280702 0.1929825#99个变量选到模型中
#50 0.2807018 0.2456140 0.2456140 0.2631579 0.2105263
#25 0.3157895 0.2456140 0.2280702 0.2631579 0.2105263
#12 0.2631579 0.2456140 0.2807018 0.2280702 0.2456140
#6  0.3508772 0.2807018 0.3157895 0.2982456 0.3508772
#3  0.3684211 0.3157895 0.3859649 0.3333333 0.3684211
#1  0.4912281 0.4736842 0.5263158 0.4912281 0.5087719

perf<- data.frame()
perf<- data.frame(
	varnum = c(row.names(auc2),row.names(error.cv2),row.names(auc2)),
	mean_value = c(auc2[,1],error.cv2[,1],auc2[,1]-error.cv2[,1]),
	sd = c(auc2[,2],error.cv2[,2],apply(AUC-error.cv,1,sd)),
	iterm = c(rep("auc",length(row.names(auc2))),rep("error",length(row.names(error.cv2))),rep("auc-error",length(row.names(auc2))))
)
write.table(perf,paste(outdir,"/","varnum-auc_error.xls",sep=""), sep="\t",quote=F)
diff <- perf[which(perf$iterm == "auc-error"),]
#best_varnum <- diff[order(diff$mean_value,decreasing=T),]$varnum[1]
if(length(which(-diff(diff$mean_value)<0)) > 0){
	best_varnum <- diff$varnum[which(-diff(diff$mean_value)<0)[length(which(-diff(diff$mean_value)<0))]+1]
}else{
	best_varnum <- 2
}
#class(best_varnum)
#upcut<-unique(as.numeric(best_varnum))
upcut<-as.numeric(as.character(best_varnum))  ## 注意格式转换 20210515
#作图
pdf(paste(outdir,"/","varnum-auc_error.pdf",sep=""),height=6,width=8)
perf$varnum <- as.numeric(as.vector(perf$varnum))
ggplot(data=perf,aes(varnum,mean_value,group=iterm))+geom_point(aes(colour=iterm),size=I(1))+geom_line(aes(colour=iterm))+geom_errorbar(aes(ymin = mean_value-sd, ymax = mean_value+sd),col="black",size=0.2)+ theme(panel.background = element_rect(colour='black'),legend.title=element_blank(), axis.text.x =element_text(angle=0, hjust=1) ) + scale_colour_manual(values=c("#00BA38","#619CFF","#F8766D")) + labs(x="Number of variables",y="Mean value",title="xxx")+geom_vline(xintercept=as.numeric(as.vector(best_varnum)),lty=2,col="purple") + scale_x_continuous(limits=range(perf$varnum),breaks=seq(range(perf$varnum)[1],range(perf$varnum)[2],5))
dev.off()

###计算基因的权重系数均值
coef <- data.frame()
#for (top_n in 2:(dim(X)[2]-1)){
for (top_n in 2:(result[[1]]$n.var[1])){  #控制变量个数不超过某个值，如500  20210531
    if(repeattimes > 1){
	merg <- data.frame(name=names(result[[1]]$coefs[[top_n]]),as.vector(result[[1]]$coefs[[top_n]]) )
	for (j in 2:repeattimes){
	    r <- data.frame(name=names(result[[j]]$coefs[[top_n]]),as.vector(result[[j]]$coefs[[top_n]]) )
	    merg <- merge(merg,r,by="name",all.x=T)
        }
	names(merg) <- c("name",paste("r",c(1:repeattimes),sep=""))
	rownames(merg) <- merg$name
	merg$name <- NULL
	merg <- as.matrix(merg)
	for(i in 1:dim(merg)[1]){
	    for(j in 1:dim(merg)[2]){
		if(is.na(merg[i,j])){merg[i,j] = 0}
	    }
	}
	merg2 <- cbind(rowMeans(merg), apply(merg,1,sd), merg)
	colnames(merg2) <- c("mean","sd",paste("r",c(1:dim(merg)[2]),sep=""))
	once_coef = data.frame(var_num=rep(top_n,top_n),gene=rownames(merg),merg2)
	coef = rbind(coef,once_coef)
    }else{
	once_coef = data.frame(var_num=rep(top_n,top_n),gene=names(result[[1]]$coefs[[top_n]]),mean=as.vector(result[[1]]$coefs[[top_n]]))
	coef = rbind(coef,once_coef)
    }
}
row.names(coef) <- NULL
write.table(coef,paste(outdir,"/","varnum-coef.xls",sep=""), sep="\t",quote=F)

keygene_coef <- coef[which(coef$var_num == best_varnum),][,c(1:4)] #
keygene_coef2 <- keygene_coef[order(keygene_coef$mean,decreasing=T),]
row.names(keygene_coef2) <- NULL
write.table(keygene_coef2,paste(outdir,"/","keygene-coef.xls",sep=""), sep="\t",quote=F)
#作图
keygene_coef2$gene <- factor(keygene_coef2$gene,levels=unique(keygene_coef2$gene))
pdf(paste(outdir,"/","keygene-coef.pdf",sep=""),height=6,width=8)
ggplot(keygene_coef2,aes(gene,mean))+geom_col(col="black")+theme(axis.text.x =element_text(angle=30, hjust=1) ) + geom_text(aes(label = paste(round(mean,digits=2),"±",round(sd,digits=2),sep=" ")),size=1.5,vjust=1.5,hjust=-0.1,angle=90,col=I("red"))+labs(x="Gene name",y="Mean coef",title=paste("xxx: top ", best_varnum," important genes") ) +geom_errorbar(aes(ymin = mean-sd, ymax = mean+sd),col="black",size=0.3,width=0.2)
dev.off()


#画图
#head_im_vars <- c( 2:(dim(X)[2]-1)) 
#dncut<-upcut
#head_im_vars <- c(dncut:upcut)
#head_im_vars <- c( 2:3 )
outpdf = paste(outdir,"/","cv_error.pdf",sep="");
pdf(outpdf)   #cv变化曲线图
matplot(result[[1]]$n.var, cbind(rowMeans(error.cv), error.cv), type="p",log="x", col=c(2, rep("grey60", ncol(error.cv))), lty=1, pch=c(19, rep(20, ncol(error.cv))),xlab="Number of variables", ylab="CV Error")
lines(result[[1]]$n.var,rowMeans(error.cv),col=2)
dev.off()
error.cv.cbm<-cbind(rowMeans(error.cv), error.cv)
m=which.min(error.cv.cbm[,1])
min_errcv_n <- as.numeric(names(m))
write.table(min_errcv_n,paste(outdir,"/","min_errcv_varnum.xls",sep=""), sep="\t",quote=F)

keygene_coef_min_errcv_n <- coef[which(coef$var_num == min_errcv_n),][,c(1:4)] #
keygene_coef_min_errcv_n2 <- keygene_coef_min_errcv_n[order(keygene_coef_min_errcv_n$mean,decreasing=T),]
row.names(keygene_coef_min_errcv_n2) <- NULL
write.table(keygene_coef_min_errcv_n2,paste(outdir,"/","keygene-coef.min_errcv.xls",sep=""), sep="\t",quote=F)

#-------------------------------------------------------  手动加入点
keygene_manual <- coef[which(coef$var_num == 12),][,c(1:4)] #
keygene_manual2 <- keygene_manual[order(keygene_manual$mean,decreasing=T),]
row.names(keygene_manual2) <- NULL
write.table(keygene_manual2,paste(outdir,"/","keygene-coef.manual.xls",sep=""), sep="\t",quote=F)
#---------------------------------------------------------------

write.table(upcut,paste(outdir,"/","min_auc-err-upcut_varnum.xls",sep=""), sep="\t",quote=F)
head_im_vars <- c(upcut)
if(min_errcv_n != upcut){
    head_im_vars <- c(head_im_vars,min_errcv_n,12)   #手动加入点
#    head_im_vars <- c(head_im_vars,min_errcv_n)
}else{
	head_im_vars <- c(head_im_vars,12) 
}

ori_outdir <- outdir
for( head_im_var in head_im_vars){
	outdir <- paste(ori_outdir,"",head_im_var,sep="")
	if(!file.exists(outdir)){
    	    dir.create(outdir)
	}
#	outpdf = paste(outdir,"/","cv_error.pdf",sep="");
#	pdf(outpdf)   #cv变化曲线图
#	matplot(result[[1]]$n.var, cbind(rowMeans(error.cv), error.cv), type="p",log="x", col=c(2, rep("grey60", ncol(error.cv))), lty=1, pch=c(19, rep(20, ncol(error.cv))),xlab="Number of variables", ylab="CV Error") 
#        lines(result[[1]]$n.var,rowMeans(error.cv),col=2)
##	abline(v=head_im_var,col="pink",lwd=2) 
#	dev.off()
#	error.cv.cbm<-cbind(rowMeans(error.cv), error.cv)
##	cutoff<-min (error.cv.cbm[,1])+sd(error.cv.cbm[,1]) #所有变量中，cv最小对应的变量数目+一个sd，
##	error.cv.cbm[error.cv.cbm[,1]<cutoff,]#取出10个变量，重复5次的cv
#	m=which.min(error.cv.cbm[,1])
#        write.table(m,paste(outdir,"/","mincv_varnum.xls",sep=""), sep="\t",quote=F)

	#######predict######
	set.seed(999)
	genes <- coef[which(coef$var_num == head_im_var),]$gene
	genes <- as.vector(genes)
	train1.lasso <- cv.glmnet(as.matrix(train_X[,genes]), train_Y, family="binomial",nlambda=100,alpha=1,standardize=F,nfolds=cv.fold,type.measure = "class")

	################ROC curve #######################
	#testset[,2:ncol(testset)][,genes]   testset[,1]
	test.pre <- predict(train1.lasso,as.matrix(testset[,2:ncol(testset)][,genes]),s=train1.lasso$lambda.min,type="response")
	if( length(unique(as.character(Y))) ==2){ #只有两个分组时候才画ROC
		realclass = factor(testset[,1],levels=c("S","R"))
		preprob = test.pre[,1];names(preprob)=NULL #取第一列为，为正概率
		outpdf = paste(outdir,"/","testset.ROC.pdf",sep="")
                pdf(outpdf)
		roc1 = roc(realclass, preprob, percent=TRUE, partial.auc.correct=TRUE,ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=FALSE,plot=F, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE)                    
		roc1 = roc(realclass, preprob, ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=F, plot=T,auc.polygon=T, percent=roc1$percent,col=2)
		sens.ci <- ci.se(roc1, specificities=seq(0, 100, 5)) #横坐标位置
		plot(sens.ci, type="shape", col=rgb(0,1,0,alpha=0.2))
		plot(sens.ci, type="bars")
		plot(roc1,col=2,add=T) 
		legend("bottomright",c(paste("AUC=",round(roc1$ci[2],2),"%"), paste("95% CI:",round(roc1$ci[1],2),"%-",round(roc1$ci[3],2),"%")),inset = 0.05)
		dev.off()

		roc_out = c(roc1$ci[2],roc1$ci[1],roc1$ci[3])
		outroc = paste(outdir,"/","testset.roc.xls",sep="")
		write.table(roc_out,outroc)
	}

	################ROC curve #######################
	#train_X[,genes]    train_Y
	train1.pre <- predict(train1.lasso,as.matrix(train_X[,genes]),s=train1.lasso$lambda.min,type="response")
	if( length(unique(as.character(Y))) ==2){ #只有两个分组时候才画ROC
		realclass = factor(train_Y,levels=c("S","R"))
		preprob = train1.pre[,1];names(preprob)=NULL #取第一列为，为正概率
		outpdf = paste(outdir,"/","trainset.ROC.pdf",sep="")
                pdf(outpdf)
		roc1 = roc(realclass, preprob, percent=TRUE, partial.auc.correct=TRUE,ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=FALSE,plot=F, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE)                    
		roc1 = roc(realclass, preprob, ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=F, plot=T,auc.polygon=T, percent=roc1$percent,col=2)
		sens.ci <- ci.se(roc1, specificities=seq(0, 100, 5)) #横坐标位置
		plot(sens.ci, type="shape", col=rgb(0,1,0,alpha=0.2))
		plot(sens.ci, type="bars")
		plot(roc1,col=2,add=T) 
		legend("bottomright",c(paste("AUC=",round(roc1$ci[2],2),"%"), paste("95% CI:",round(roc1$ci[1],2),"%-",round(roc1$ci[3],2),"%")),inset = 0.05)
		dev.off()

		roc_out = c(roc1$ci[2],roc1$ci[1],roc1$ci[3])
		outroc = paste(outdir,"/","trainset.roc.xls",sep="")
		write.table(roc_out,outroc)
	}
}
