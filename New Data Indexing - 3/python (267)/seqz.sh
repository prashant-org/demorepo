#!/bin/sh

# seqz.sh
# Author: Chin-Chen Pan
# Directore, General and Surgical Pathology
# Professor, attending pathologist
# Department of Pathology and Laboratory Medicine
# Taipei Veterans General Hospital
# TAIWAN
# Version 3.2.1
# Date: Jan 11, 2021

# git clone https://bitbucket.org/sequenza_tools/sequenza-utils
# cd sequenza-utils
# sudo python setup.py install
# sudo R
# source("https://bioconductor.org/biocLite.R")
#        biocLite("copynumber")
# install.packages("sequenza")

[ $# -lt 3 ] && echo "\nToo few arguments!\n\nArgument1 (required): Sample name\nArgument2 (required): Mate name\nArgument3 (required): Output directory\n\nOptions:\n  chrN: The chromosome number whose average Log2Ratio the baseline is adjusted to.  \n\nOptions:\n  -s: shutdown after finished\n\nNote: Run the program in sudo as \necho 'password' | sudo -S sh seqz.sh test normal seqz_output chr3\n" && exit

[ `id -u` != "0" ] && echo "Please run as root (sudo)." && exit

[ ! -f ./exome_test.config ] && echo "exome_test.config not exists.\n" && exit
read sh_user sh_inputdir sh_outputdir sh_thread < ./exome_test.config

[ ! -f $sh_user/hg19.gc50Base.txt.gz -o ! -f $sh_user/hg19/hg19.fa -o ! -f $sh_user/seqz.tmp -o ! -d $sh_user/cytoband_loc -o ! -f $sh_user/cnv_annotate.sh ] && echo "\nPlease check all of the followings are present: \n\n$sh_user/hg19.gc50Base.txt.gz\n$sh_user/hg19/hg19.fa\n$sh_user/seqz.tmp\n$sh_user/cytoband_loc\n$sh_user/cnv_annotate.sh\n" && exit

chrom_mean="0"

if [ $# -gt 3 ]; then
[ $4 = "chr1" -o $4 = "chr2" -o $4 = "chr3" -o $4 = "chr4" -o $4 = "chr5" -o $4 = "chr6" -o $4 = "chr7" -o $4 = "chr8" -o $4 = "chr9" -o $4 = "chr10" -o $4 = "chr11" -o $4 = "chr12" -o $4 = "chr13" -o $4 = "chr14" -o $4 = "chr15" -o $4 = "chr16" -o $4 = "chr17" -o $4 = "chr18" -o $4 = "chr19" -o $4 = "chr20" -o $4 = "chr21" -o $4 = "chr22" -o $4 = "chrX" -o $4 = "chrY" ] && chrom_mean=`echo $4 | cut -c 4-`
fi


mkdir -p $sh_outputdir/$3

logfile="$sh_outputdir/$3/seqz-$1.log"

tab=`echo "\t"`

echo "# Author: Chin-Chen Pan\n# Directore, General and Surgical Pathology\n# Professor, attending pathologist\n# Department of Pathology and Laboratory Medicine\n# Taipei Veterans General Hospital\n# TAIWAN\n# Version 3.2.1\n\nUser path: $sh_user\nInput path: $sh_inputdir\nOutput path: $sh_outputdir\nThread number: $sh_thread\nInputfile1: $1\nNormal refernece:$2\n\nArguments: $*\n" >> $logfile

echo "seqz.sh started: `date '+%c'`\n" >> $logfile
if [ -f $sh_outputdir/$3/$1.seg ]; then
echo "\n$sh_outputdir/$3/$1.seg exists.\n" | tee -a $logfile
else
if [ -f $sh_outputdir/$3/$1.small.seqz.gz ]; then
echo "\n$sh_outputdir/$3/$1.small.seqz.gz exists.\n" | tee -a $logfile
else
if [ ! -f $sh_outputdir/$3/$1.seqz ]; then 
[ ! -f $sh_outputdir/$1/exome/$1.marked.realigned.fixed.recal.bam -o ! -f $sh_outputdir/$2/exome/$2.marked.realigned.fixed.recal.bam ] && echo "$sh_outputdir/$1/exome/$1.marked.realigned.fixed.recal.bam or $sh_outputdir/$2/exome/$2.marked.realigned.fixed.recal.bam not present." | tee -a $logfile && exit
#echo "\nsequenza-utils bam2seqz -gc $sh_user/hg19.gc50Base.txt.gz --fasta $sh_user/hg19/hg19.fa -n $sh_outputdir/$2/exome/$2.marked.realigned.fixed.recal.bam -t $sh_outputdir/$1/exome/$1.marked.realigned.fixed.recal.bam | sed /hap/d | sed /random/d | sed /chrUn/d | sed /chrM/d | gzip > $sh_outputdir/$3/$1.seqz.gz"
#sequenza-utils bam2seqz -gc $sh_user/hg19.gc50Base.txt.gz --fasta $sh_user/hg19/hg19.fa -n $sh_outputdir/$2/exome/$2.marked.realigned.fixed.recal.bam -t $sh_outputdir/$1/exome/$1.marked.realigned.fixed.recal.bam | sed /hap/d | sed /random/d | sed /chrUn/d | sed /chrM/d | gzip > $sh_outputdir/$3/$1.seqz.gz
#if [ $sh_thread -gt 23 ]; then
# noparallel=24
#elif [ $sh_thread -gt 11 -a $sh_thread -lt 24 ]; then
# noparallel=12
#elif [ $sh_thread -gt 7 -a $sh_thread -lt 12 ]; then
# noparallel=8
#elif [ $sh_thread -gt 3 -a $sh_thread -lt 8 ]; then
# noparallel=4
#else
# noparallel=1
#fi
echo "\nsequenza-utils bam2seqz -gc $sh_user/hg19.gc50Base.txt.gz -C chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY --parallel $sh_thread --fasta $sh_user/hg19/hg19.fa -n $sh_outputdir/$2/exome/$2.marked.realigned.fixed.recal.bam -t $sh_outputdir/$1/exome/$1.marked.realigned.fixed.recal.bam --output $sh_outputdir/$3/$1\n"
sequenza-utils bam2seqz -gc $sh_user/hg19.gc50Base.txt.gz -C chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY --parallel $sh_thread --fasta $sh_user/hg19/hg19.fa -n $sh_outputdir/$2/exome/$2.marked.realigned.fixed.recal.bam -t $sh_outputdir/$1/exome/$1.marked.realigned.fixed.recal.bam --output $sh_outputdir/$3/$1 
head -n 1 $sh_outputdir/$3/$1_chr1 > $sh_outputdir/$3/$1.seqz
cat $sh_outputdir/$3/$1_chr1 $sh_outputdir/$3/$1_chr2 $sh_outputdir/$3/$1_chr3 $sh_outputdir/$3/$1_chr4 $sh_outputdir/$3/$1_chr5 $sh_outputdir/$3/$1_chr6 $sh_outputdir/$3/$1_chr7 $sh_outputdir/$3/$1_chr8 $sh_outputdir/$3/$1_chr9 $sh_outputdir/$3/$1_chr10 $sh_outputdir/$3/$1_chr11 $sh_outputdir/$3/$1_chr12 $sh_outputdir/$3/$1_chr13 $sh_outputdir/$3/$1_chr14 $sh_outputdir/$3/$1_chr15 $sh_outputdir/$3/$1_chr16 $sh_outputdir/$3/$1_chr17 $sh_outputdir/$3/$1_chr18 $sh_outputdir/$3/$1_chr19 $sh_outputdir/$3/$1_chr20 $sh_outputdir/$3/$1_chr21 $sh_outputdir/$3/$1_chr22 $sh_outputdir/$3/$1_chrX $sh_outputdir/$3/$1_chrY | sed /chromosome/d >> $sh_outputdir/$3/$1.seqz
#gzip -f $sh_outputdir/$3/$1.seqz
echo "bam2seqz finished: `date '+%c'`\n" >> $logfile
else
echo "\n$sh_outputdir/$3/$1.seqz exists.\n" | tee -a $logfile
fi
[ -f $sh_outputdir/$3/$1.seqz ] && echo "\nsequenza−utils seqz_binning −w 50 −s $sh_outputdir/$3/$1.seqz | gzip > $sh_outputdir/$3/$1.small.seqz.gz\n" && sequenza-utils seqz_binning -w 50 -s $sh_outputdir/$3/$1.seqz | gzip > $sh_outputdir/$3/$1.small.seqz.gz && echo "seqz_binning finished: `date '+%c'`\n" >> $logfile
fi

cd ~

[ ! -f $sh_outputdir/$3/$1.small.seqz.gz ] && echo "$sh_outputdir/$3/$1.small.seqz.gz failed." && exit

[ ! -f $sh_outputdir/$3/$1.seqz.table ] && echo "\nRunning R script...\n" && cat $sh_user/seqz.tmp | sed "s|inputfile|$sh_outputdir\/$3\/$1.small.seqz.gz|" | sed "s|outputfile|$sh_outputdir\/$3\/$1.seqz.table|" | sed "s|samplename|$1|g" | sed "s|outputpath|$sh_outputdir\/$3|g" > $sh_outputdir/$3/$1.seqz.R && Rscript --verbose $sh_outputdir/$3/$1.seqz.R && echo "R script finished: `date '+%c'`\n" >> $logfile || echo "\n$sh_outputdir/$3/$1.seqz.table exists.\n" | tee -a $logfile

[ -f $sh_outputdir/$3/$1.seqz.table ] && cat $sh_outputdir/$3/$1.seqz.table | awk -F '\t' ' NR>1 {print "'"$1"'" "\t" $2 "\t" $3 "\t" $4 "\t" $6 "\t" log($8)/log(2) }' | sed 's/chr//g' | sed 's/"//g' > $sh_outputdir/$3/$1.seg || echo "\n$sh_outputdir/$3/$1.seqz.table not exist.\n"
fi

if [ ! -f $sh_outputdir/$3/$1.adjusted.seg ]; then
[ $chrom_mean != "0" ] && meanratio=`cat $sh_outputdir/$3/$1.seg | awk -F '\t' '($2 == "'"$chrom_mean"'"){ total += $6; total_line +=1 } END { print total/total_line }'` && echo "Adjusted baseline=$meanratio (average Log2Ratio of chromosome $chrom_mean)\n" | tee -a $logfile && awk -F '\t' '{print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6-"'"$meanratio"'"}' $sh_outputdir/$3/$1.seg > $sh_outputdir/$3/$1.adjusted.seg || cp $sh_outputdir/$3/$1.seg $sh_outputdir/$3/$1.adjusted.seg
fi

chmod -R 777 $sh_outputdir/$3

echo "seqz.sh finished: `date '+%c'`\n" | tee -a $logfile

mkdir -p $sh_outputdir/$3/tmp

if [ ! -f $sh_outputdir/$3/$1.adjusted.seg.cytoband.tsv ]; then
totalline=0
splitline=0
totalline="`cat $sh_outputdir/$3/$1.adjusted.seg | wc -l`"
res=$((totalline % sh_thread))
res=$((totalline + sh_thread - res))
splitline=`expr $res / $sh_thread`
echo "Total line of $sh_outputdir/$3/$1.adjusted.seg = $totalline\nLine in splitted file: $splitline"
cat $sh_outputdir/$3/$1.adjusted.seg | awk -F '\t' '{ print $1 "\tchr" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6}' | split -l $splitline -d -a 2 - $sh_outputdir/$3/tmp/$1.adjusted.seg
li=0
cd $sh_outputdir/$3/tmp
while [ $li -lt $sh_thread ]
do
[ $li -lt 10 ] && tempsh=$1.adjusted.seg0$li || tempsh=$1.adjusted.seg$li
sh $sh_user/cnv_annotate.sh $tempsh $sh_user&
li=$((li+1))
done
wait
echo "Chromosome\tStart\tEnd\tNum_Probes\tSegment_Mean\tCytoband_Start\tCytoband_End" > $sh_outputdir/$3/$1.adjusted.seg.cytoband.tsv
cat $1.adjusted.seg*.annotate | cut -f2-8 | sort -t "$tab" -V -k1,1 -k2,2n | awk -F '\t' '{ print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" substr($1,4) $6 "\t" substr($1,4) $7}' >> $sh_outputdir/$3/$1.adjusted.seg.cytoband.tsv
echo "Annotation of $1.adjusted.seg.cytoband.tsv done: `date '+%c'`\n" | tee -a $logfile
fi

chmod -R 777 $sh_outputdir/$3

case "$* " in
 *" -kt "*)
 ;;
 *)
 [ -s $sh_outputdir/$3/$1.small.seqz.gz -o -s $sh_outputdir/$3/$1.seqz ] && rm -f $sh_outputdir/$3/$1_chr1 $sh_outputdir/$3/$1_chr2 $sh_outputdir/$3/$1_chr3 $sh_outputdir/$3/$1_chr4 $sh_outputdir/$3/$1_chr5 $sh_outputdir/$3/$1_chr6 $sh_outputdir/$3/$1_chr7 $sh_outputdir/$3/$1_chr8 $sh_outputdir/$3/$1_chr9 $sh_outputdir/$3/$1_chr10 $sh_outputdir/$3/$1_chr11 $sh_outputdir/$3/$1_chr12 $sh_outputdir/$3/$1_chr13 $sh_outputdir/$3/$1_chr14 $sh_outputdir/$3/$1_chr15 $sh_outputdir/$3/$1_chr16 $sh_outputdir/$3/$1_chr17 $sh_outputdir/$3/$1_chr18 $sh_outputdir/$3/$1_chr19 $sh_outputdir/$3/$1_chr20 $sh_outputdir/$3/$1_chr21 $sh_outputdir/$3/$1_chr22 $sh_outputdir/$3/$1_chrX $sh_outputdir/$3/$1_chrY
 [ -s $sh_outputdir/$3/$1.small.seqz.gz ] && rm -f $sh_outputdir/$3/$1.seqz && rm -f $sh_outputdir/$3/$1.seqz.gz
 rm -rf $sh_outputdir/$3/$1.seqz.R $sh_outputdir/$3/tmp $sh_outputdir/$3/$1_sequenza_cp_table.RData $sh_outputdir/$3/$1_sequenza_extract.RData
esac


case "$* " in
 *" -s "*)
 echo "\nIf password is asked for shutdown, run sudo visudo and add the following line:\n\nuser(your username) ALL=(ALL) NOPASSWD: /sbin/shutdown\n\n"
 sudo shutdown -h now
 ;;
esac

