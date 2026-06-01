#!usr/bin/python
# -*- coding: utf-8 -*-
import sys
from sklearn import metrics
from sklearn.metrics import auc 
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import argparse,os
from collections import defaultdict


def file2list(ii):
    true=[]
    foldchange=[]
    true_positive_dict=defaultdict(chr)
    true_negative_dict=defaultdict(chr)
    with open(ii,"r") as ff:
        for line in ff.readlines()[1:]:
            line=line.strip('\n')
            arr=line.split('\t')
            if arr[3] == 'R':
                arr[3]=1
                true_positive_dict[arr[0]]=arr[2] #score
            else:
                arr[3]=0
                true_negative_dict[arr[0]]=arr[2] #score

            true.append(arr[3])
            foldchange.append(float(arr[2]))
    return [true,foldchange,true_positive_dict,true_negative_dict]

def ClassifyPerformance(cutoff,true_positive_dict,true_negative_dict):
    true_positive=0
    false_positive=0
    true_negative=0
    false_negative=0
    #print(cutoff)
    for sample in true_positive_dict.keys():
        if float(cutoff)==0:
            if float(true_positive_dict[sample]) > float(cutoff):
                true_positive+=1
            else:
                false_negative+=1
        else:
            if float(true_positive_dict[sample]) >= float(cutoff):
                true_positive+=1
            else:
                false_negative+=1
    for sample in true_negative_dict.keys():
        if float(cutoff)==0:
            if float(true_negative_dict[sample]) > float(cutoff):
                false_positive+=1
            else:
                true_negative+=1
        else:
            if float(true_negative_dict[sample]) >= float(cutoff):
                false_positive+=1
            else:
                true_negative+=1
    print(f"{cutoff}\t{true_positive}\t{false_positive}\t{true_negative}\t{false_negative}\n")
    Sensitity=true_positive/(true_positive+false_negative)
    Specificity=true_negative/(true_negative+false_positive)
    PPV=true_positive/(true_positive+false_positive)
    NPV=true_negative/(true_negative+false_negative)
    VME=false_negative/(true_positive+false_negative)  #1-Sensitity
    ME=false_positive/(true_negative+false_positive)  #1-Specificity
    Accuracy=(true_positive+true_negative)/(true_positive+true_negative+false_positive+false_negative)
    performance=f"{true_positive}\t{false_positive}\t{true_negative}\t{false_negative}\t{Sensitity}\t{Specificity}\t{PPV}\t{NPV}\t{VME}\t{ME}\t{Accuracy}"
    return performance

def auc_curve(true,foldchange,name,true_positive_dict,true_negative_dict,title):
    fpr, tpr, thresholds = metrics.roc_curve(true, foldchange) #drop_intermediate=False
    roc_auc = auc(fpr,tpr)
    plt.figure()
    lw = 3
    plt.figure(figsize=(6,6))
    plt.plot(fpr, tpr, color='darkorange', lw=lw,label='ROC curve (area = %0.3f)' % roc_auc) 
    value=open(name+'.process.txt','w')
    value.write("#"+name+" AUC:\t"+str(roc_auc)+"\n")
    value.write("Cutoff\tFPR\tTPR\tTNR\n")
    cutoff=open(name+".cutoff.value","w")
    cutoff.write("#Drug\tAUC\tscore\ttrue_positive\tfalse_positive\ttrue_negative\tfalse_negative\tSensitity(true_positive/(true_positive+false_negative))\tSpecificity(true_negative/(true_negative+false_positive))\tPPV(true_positive/(true_positive+false_positive))\tNPV(true_negative/(true_negative+false_negative))\tVME(false_negative/(true_positive+false_negative))\tME(false_positive/(true_negative+false_positive))\tAccuracy((true_positive+true_negative)/(true_positive+true_negative+false_positive+false_negative))\tYoudenCutoff\n")
    cutoff_list=[]
    for i in range(len(fpr)):
        cutoff_list.append((1-float(fpr[i]))*float(tpr[i]))
    maxindex=cutoff_list.index(max(cutoff_list))
    for i in range(len(fpr)):
   #     score_Cutoff=[]
        score=thresholds[i]
        #if float(thresholds[i]) == 0 or i==0 :
        if i == 0 :
        #    print(thresholds[i])
            continue
        #    continue
        performance=ClassifyPerformance(float(thresholds[i]),true_positive_dict,true_negative_dict)
        youden='-'
        if i==maxindex:
            youden="Yes"
        #cutoff.write(f"{score}\t{true_positive}\t{false_positive}\t{true_negative}\t{false_negative}\t{Sensitity}\t{Specificity}\t{PPV}\t{NPV}\t{VME}\t{ME}\t{Accuracy}\t{youden}\n")
        cutoff.write(f"{name}\t{roc_auc}\t{score}\t{performance}\t{youden}\n")
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
            plt.text(a,b,txt,ha = 'center',va = 'bottom',fontsize=8)
    plt.plot([0, 1], [0, 1], color='navy', lw=lw, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.0])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title(title)
    plt.legend(loc="lower right")
    plt.show()
    plt.savefig(name+".roc.pdf")
    plt.savefig(name+".roc.png")

parser = argparse.ArgumentParser(description="cal ROC")
parser.add_argument('-i', '--input', help='input',required=True)
parser.add_argument('-p', '--prefix', help='the prefix')
parser.add_argument('-t', '--title', help='the title')
argv = vars(parser.parse_args())

auc_curve(file2list(argv['input'])[0],file2list(argv['input'])[1],argv['prefix'],file2list(argv['input'])[2],file2list(argv['input'])[3],argv['title'])
