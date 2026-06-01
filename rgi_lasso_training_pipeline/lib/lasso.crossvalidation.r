##lasso.crossvalidation.r##
##Begin##
lasso.cv <-function (trainx, trainy, cv.fold = 10, ...){
	library(glmnet)
	library(pROC)
#	auc <- c()
#	class.error <- c()
	cv.model <- cv.glmnet(trainx,trainy,family="binomial",nlambda=100,alpha=1,standardize=F,nfolds=cv.fold,type.measure = "class") #指定交叉验证选取模型时希望最小化的目标参量,type.measure=class使用模型分类的错误率
	predict<-predict(cv.model, trainx,s=cv.model$lambda.min,type="response")
	roc.predict<-roc(trainy,as.numeric(predict))
#	auc <- c(auc,as.numeric(roc.predict$auc))
#	mean_error <- cv.model$cvm[which(cv.model$lambda==cv.model$lambda.min)]
#	class.error <- c(class.error,mean_error)

	coefficients<-coef(cv.model,s=cv.model$lambda.min)
	var_coef <- c()
	var_names <- c()
	for(i in 1:length(coefficients)){
	    if(row.names(coefficients)[i] != "(Intercept)"){
		var_coef <- c(var_coef,coefficients[i])
		var_names <- c(var_names,row.names(coefficients)[i])
	    }
	}
	names(var_coef) <- var_names
	var_coef_sort <- sort(var_coef,decreasing=T)
	n = length(var_coef_sort)
	z=1000
	if(n<=z){z=n}
	n.var = z:2  #不同变量个数的梯度设置

	coefs <- vector(z, mode = "list")
	#for (i in n:2) coefs[[i]] <- rep(0,i)
	#coefs[[n]] <- var_coef_sort
	auc <- c()
	class.error <- c()
	
	for (i in z:2){
	    trainx2 <- as.matrix(trainx[,names(var_coef_sort[1:i])])
	    colnames(trainx2) <- names(var_coef_sort[1:i])
	    cv.model2 <- cv.glmnet(trainx2,trainy,family="binomial",nlambda=100,alpha=1,standardize=F,nfolds=cv.fold,type.measure = "class")
	    coefficients2<-coef(cv.model2,s=cv.model2$lambda.min)
	    var_coef2 <- c()
	    var_names2 <- c()
	    for(j in 1:length(coefficients2)){
		if(row.names(coefficients2)[j] != "(Intercept)"){
		    var_coef2 <- c(var_coef2,coefficients2[j])
	    	    var_names2 <- c(var_names2,row.names(coefficients2)[j])
		}
	    }
	    names(var_coef2) <- var_names2
	    var_coef_sort <- sort(var_coef2,decreasing=T)
	    coefs[[i]] <- var_coef_sort

	    predict2<-predict(cv.model2, trainx2,s=cv.model2$lambda.min,type="response")
	    roc.predict2<-roc(trainy,as.numeric(predict2))
	    auc <- c(auc,as.numeric(roc.predict2$auc))
	    mean_error2 <- cv.model2$cvm[which(cv.model2$lambda==cv.model2$lambda.min)]
	    class.error <- c(class.error,mean_error2)
	}
	
	names(auc) <- names(class.error) <- n.var
	list(n.var = n.var, error.cv = class.error, AUC = auc, coefs=coefs)
}
 
