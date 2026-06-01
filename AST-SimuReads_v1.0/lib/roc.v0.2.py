#!usr/bin/python
# -*- coding: utf-8 -*-
import sys
from sklearn import metrics
from sklearn.metrics import auc 
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import argparse,os

def file2list(ii):
    true=[]
    foldchange=[]
    with open(ii,"r") as ff:
        for line in ff.readlines()[1:]:
            line=line.strip('\n')
            arr=line.split('\t')
            if arr[3] == 'R':
                arr[3]=1
            else:
                arr[3]=0
            true.append(arr[3])
            foldchange.append(float(arr[2]))
    return true,foldchange

def auc_curve(true,foldchange,name):
    fpr, tpr, thresholds = metrics.roc_curve(true, foldchange) #drop_intermediate=False
    roc_auc = auc(fpr,tpr)
    plt.figure()
    lw = 3
    plt.figure(figsize=(15,15))
    plt.plot(fpr, tpr, color='darkorange', lw=lw,label='ROC curve (area = %0.3f)' % roc_auc) 
    value=open(name+'.process.txt','w')
    value.write("#"+name+" AUC:\t"+str(roc_auc)+"\n")
    value.write("Cutoff\tFPR\tTPR\tTNR\n")
    cutoff=open(name+".cutoff.value","w")
    cutoff.write("#YoudenIndexcutoff\tTPR\tTNR\n")
    cutoff_list=[]
    for i in range(len(fpr)):
#        cutoff_list.append((1-float(fpr[i]))*float(tpr[i]))
        cutoff_list.append((1-float(fpr[i]))+float(tpr[i])-1)  ##J Statistic Youden Index = Sensitivity + Specificity – 1
    maxindex=cutoff_list.index(max(cutoff_list))
    #cutoffsel='%.3f' % thresholds[maxindex]
    cutoffsel=thresholds[maxindex] #20210416 cutoff点不能随便进行四舍五入
    cutoff.write(str(cutoffsel)+"\t"+str(tpr[maxindex])+"\t"+str(1-float(fpr[maxindex]))+"\n")
    for a,b,c in zip(fpr,tpr,thresholds):
        pa=('%.3f' % float(a.item()))
        tnp=1-float(a.item())
        pd=('%.3f' % (tnp))
        pb=('%.3f' % float(b.item()))
        #pc=('%.3f' % float(c.item()))
        pc=float(c.item()) #20210416 临界点取>=，不进行四舍五入计算，不然会影响后续临界点的PPV
        value.write(str(pc)+"\t"+str(pa)+"\t"+str(pb)+"\t"+str(pd)+"\n")
        if (a<0.1 and b>0.95 ) or (a<0.05 and b>0.9) :#敏感性95% 特异性90%以上
            aa=('%.3f' % float(a.item()))
            bb=('%.3f' % float(b.item()))
            txt=str(aa)+","+str(bb)
            plt.text(a,b,txt,ha = 'center',va = 'bottom',fontsize=10)
    plt.plot([0, 1], [0, 1], color='navy', lw=lw, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.0])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('Receiver operating characteristic example')
    plt.legend(loc="lower right")
    plt.show()
    plt.savefig(name+".roc.pdf")

parser = argparse.ArgumentParser(description="cal ROC")
parser.add_argument('-i', '--input', help='input',required=True)
parser.add_argument('-p', '--prefix', help='the prefix')
argv = vars(parser.parse_args())

auc_curve(file2list(argv['input'])[0],file2list(argv['input'])[1],argv['prefix'])
