#!/bin/sh

# somatic.sh
# Author: Chin-Chen Pan
# Directore, General and Surgical Pathology
# Professor, attending pathologist
# Department of Pathology and Laboratory Medicine
# Taipei Veterans General Hospital
# TAIWAN
# Version 2.2.2
# Date: Apr. 19, 2021

[ ! -f ./exome_test.config ] && echo "exome_test.config not exists.\n" && exit

read sh_user sh_inputdir sh_outputdir sh_thread < ./exome_test.config

echo "\nUser path: $sh_user\nInput path: $sh_inputdir\nOutput path: $sh_outputdir\nThread number: $sh_thread\n"
sh_nthread=`expr $sh_thread`


dpkg -l | grep -qw python-dev || sudo apt-get install python-dev
dpkg -l | grep -qw default-jre || sudo apt-get install default-jre


[ $# -lt 2 ] && echo "\nToo few arguments!\n\nArgument1 (required): Sample\nArgument2 (required): Normal\nThe Sample.chr#.mpileup and Normal.chr#.mpileup must be present in $sh_outputdir/Sample/exome/mpileup\nOptions:\n  -s: shutdown after finished\n  -kt: keep temporary files" && exit
[ ! -d $sh_outputdir/$1/exome ] && echo "$sh_outputdir/$1/exome not exist!\n" && exit


[ ! -f $sh_user/VarScan.v2.3.9.jar -o ! -d $sh_user/annovar -o ! -f $sh_user/vs_format_converter.py -o ! -d $sh_user/dbSNPnew -o ! -d $sh_user/clinvar -o ! -d $sh_user/cosmic ] && echo "\nPlease check all of the followings are present: \n\n$sh_user/VarScan.v2.3.9.jar\n$sh_user/annovar\n$sh_user/vs_format_converter.py\n$sh_user/dbSNPnew\n$sh_user/clinvar\n$sh_user/cosmic\n" && exit

tab=`echo "\t"`

mri=$((24 / sh_nthread))
res=$((24 % sh_nthread))
[ $res -gt 0 ] && mri=$((mri+1))

mkdir -p $sh_outputdir/$1/exome/somatic/tmp

if [ ! -f $sh_outputdir/$1/exome/somatic/$1.snp -o ! -f $sh_outputdir/$1/exome/somatic/$1.indel ]; then
[ ! -f $sh_outputdir/$1/exome/mpileup/$1.chrY.mpileup ] && echo "\n$1.mpileup files NOT EXIST!\n" && exit

if [ ! -f $sh_outputdir/$1/exome/mpileup/$2.chrY.mpileup ]; then
 [ ! -f $sh_outputdir/$2/exome/mpileup/$2.chrY.mpileup ] && echo "\n$2.mpileup files NOT EXIST!\n" && exit || ln -sf $sh_outputdir/$2/exome/mpileup/* $sh_outputdir/$1/exome/mpileup
fi


if [ ! -f $sh_outputdir/$1/exome/mpileup/$1.chrY.snp -o ! -f $sh_outputdir/$1/exome/mpileup/$1.chrY.indel ]; then
cd $sh_outputdir/$1/exome/mpileup
 li=1
 ri=0
 mli=1
while [ $ri -lt $mri ]
 do
 mli=$((ri * $sh_nthread + $sh_nthread +1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && java -jar $sh_user/VarScan.v2.3.9.jar somatic $2.chr$li.mpileup $1.chr$li.mpileup $1.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
java -jar $sh_user/VarScan.v2.3.9.jar somatic $2.chrX.mpileup $1.chrX.mpileup $1.chrX&
java -jar $sh_user/VarScan.v2.3.9.jar somatic $2.chrY.mpileup $1.chrY.mpileup $1.chrY&
wait
fi
head -n 1 $sh_outputdir/$1/exome/mpileup/$1.chr1.snp > $sh_outputdir/$1/exome/somatic/$1.snp
head -n 1 $sh_outputdir/$1/exome/mpileup/$1.chr1.indel > $sh_outputdir/$1/exome/somatic/$1.indel
cat $1.chr1.snp $1.chr2.snp $1.chr3.snp $1.chr4.snp $1.chr5.snp $1.chr6.snp $1.chr7.snp $1.chr8.snp $1.chr9.snp $1.chr10.snp $1.chr11.snp $1.chr12.snp $1.chr13.snp $1.chr14.snp $1.chr15.snp $1.chr16.snp $1.chr17.snp $1.chr18.snp $1.chr19.snp $1.chr20.snp $1.chr21.snp $1.chr22.snp $1.chrX.snp $1.chrY.snp | sed '/^chrom/d' >> $sh_outputdir/$1/exome/somatic/$1.snp
cat $1.chr1.indel $1.chr2.indel $1.chr3.indel $1.chr4.indel $1.chr5.indel $1.chr6.indel $1.chr7.indel $1.chr8.indel $1.chr9.indel $1.chr10.indel $1.chr11.indel $1.chr12.indel $1.chr13.indel $1.chr14.indel $1.chr15.indel $1.chr16.indel $1.chr17.indel $1.chr18.indel $1.chr19.indel $1.chr20.indel $1.chr21.indel $1.chr22.indel $1.chrX.indel $1.chrY.indel | sed '/^chrom/d' >> $sh_outputdir/$1/exome/somatic/$1.indel
else
echo "\n$sh_outputdir/$1/exome/somatic/$1.snp $sh_outputdir/$1/exome/somatic/$1.indel exists!\n"
fi

somatic_title="chrom\tposition\tref\tvar\tnormal_reads1\tnormal_reads2\tnormal_var_freq\tnormal_gt\ttumor_reads1\ttumor_reads2\ttumor_var_freq\ttumor_gt\tsomatic_status\tvariant_p_value\tsomatic_p_value\ttumor_reads1_plus\ttumor_reads1_minus\ttumor_reads2_plus\ttumor_reads2_minus\tnormal_reads1_plus\tnormal_reads1_minus\tnormal_reads2_plus\tnormal_reads2_minus\tid"

[ ! -f $sh_outputdir/$1/exome/somatic/$1.snp.Somatic ] && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.snp.Germline && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.snp.LOH && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.snp.Somatic && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.snp.Unknown && awk -F '\t' 'NR>1 {print $0 "\t" $1 "-" $2 $3 "-" $4 >> "'"$sh_outputdir/$1/exome/somatic/$1.snp"'" "." $13}' $sh_outputdir/$1/exome/somatic/$1.snp 

[ ! -f $sh_outputdir/$1/exome/somatic/$1.indel.Somatic ] && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.indel.Germline && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.indel.LOH && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.indel.Somatic && echo $somatic_title > $sh_outputdir/$1/exome/somatic/$1.indel.Unknown &&  cat $sh_outputdir/$1/exome/somatic/$1.indel | awk -F '\t' 'NR>1 {print $0}' |  awk -F '\t' '{if (substr($4,1,1) == "+") {print $0 "\t" $1 "-" $2 "--" substr($4,2,length($4)-1) >> "'"$sh_outputdir/$1/exome/somatic/$1.indel"'" "." $13 } else {print $0 "\t" $1 "-" $2+1 substr($4,2,length($4)-1) "--" >> "'"$sh_outputdir/$1/exome/somatic/$1.indel"'" "." $13 }}'

cd $sh_user/annovar

if [ ! -f $sh_outputdir/$1/exome/$1.somatic.txt ]; then
if [ ! -f $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt ]; then
[ ! -f $sh_outputdir/$1/exome/$1.somatic.annovar ] && python $sh_user/vs_format_converter.py $sh_outputdir/$1/exome/somatic/$1.snp.Somatic | perl convert2annovar.pl --format vcf4 --includeinfo -allsample -withfreq stdin > $sh_outputdir/$1/exome/$1.somatic.annovar || echo "$sh_outputdir/$1/exome/$1.somatic.annovar exists."
perl table_annovar.pl $sh_outputdir/$1/exome/$1.somatic.annovar humandb/ -buildver hg19 -out $sh_outputdir/$1/exome/$1.somatic.table -thread $sh_nthread --maxgenethread $sh_nthread -remove -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,1000g2014oct_all,1000g2014oct_afr,1000g2014oct_eas,1000g2014oct_eur,clinvar_20150330,cosmic70,dbnsfp30a,exac03nontcga -operation g,r,r,f,f,f,f,f,f,f,f,f -nastring . 
else
[ `head -n 1 $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt | awk -F '\t' '{print NF}'` -ne 61 ] && echo "\nWrong column number of $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt. Please delete the file and re-run." && exit
echo "$sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt exists."
fi
if [ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.txt ]; then
[ ! -f $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt ] && echo "$sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt not exists" && exit
cd $sh_outputdir/$1/exome/somatic/tmp
rm -f $1.somatic.cosmic.id.chr* $1.somatic.cosmic.chr*  
awk -F '\t' '($1 ~ /^chr..?$/) {print $1 "-" $2 $4 "-" $5 }' $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt | sort | awk -F '\t' '{print $1 >> "'"$1"'" ".somatic.cosmic.id." substr($1, 1, index($1,"-")-1)}'
li=1
while [ $li -lt 23 ]
do
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chr$li ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chr$li
li=$((li+1))
done
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chrX ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chrX
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chrY ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chrY
cd $sh_outputdir/$1/exome
 li=1
 ri=0
 mli=1
 while [ $ri -lt $mri ]
 do
 mli=$((ri * sh_nthread + sh_nthread + 1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && zcat $sh_user/cosmic/cosmic.id.chr$li.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chr$li  -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
 zcat $sh_user/cosmic/cosmic.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chrX -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.chrX&
 zcat $sh_user/cosmic/cosmic.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.id.chrY -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.chrY&
 wait
cat $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.chr*  | sort -t "$tab" -k 2,2 > $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.txt
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.txt Finished"
else
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.txt exists!" 
fi

if [ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.txt ]; then
[ ! -f $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt ] && echo "$sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt not exists" && exit
cd $sh_outputdir/$1/exome/somatic/tmp
rm -f $1.somatic.clinvar.id.chr* $1.somatic.clinvar.chr*  
awk -F '\t' '($1 ~ /^chr..?$/) {print $1 "-" $2 $4 "-" $5 }' $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt | sort | awk -F '\t' '{print $1 >> "'"$1"'" ".somatic.clinvar.id." substr($1, 1, index($1,"-")-1)}'
li=1
while [ $li -lt 23 ]
do
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chr$li ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chr$li
li=$((li+1))
done
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chrX ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chrX
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chrY ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chrY
cd $sh_outputdir/$1/exome
 li=1
 ri=0
 mli=1
 while [ $ri -lt $mri ]
 do
 mli=$((ri * sh_nthread + sh_nthread + 1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && zcat $sh_user/clinvar/clinvar.id.chr$li.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chr$li  -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
 zcat $sh_user/clinvar/clinvar.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chrX -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.chrX&
 zcat $sh_user/clinvar/clinvar.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.id.chrY -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.chrY&
 wait
cat $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.chr*  | sort -t "$tab" -k 2,2 > $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.txt
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.txt Finished"
else
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.txt exists!" 
fi


if [ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.tmp ]; then
rm -f $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chr* $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.newdbsnp.chr*
li=1
while [ $li -lt 23 ]
do
touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chr$li
li=$((li+1))
done
touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chrX
touch $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chrY

cat $sh_outputdir/$1/exome/$1.somatic.table.hg19_multianno.txt | sed '1d' | awk -F '\t' '{print $1 "-" $2 $4 "-" $5 "\t" $0 }' | sort -t "$tab" -k 1,1 | awk -F '\t' '{print $0 >> "'"$sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp."'" substr($1, 1, index($1,"-")-1)}'

 li=1
 ri=0
 mli=1
 while [ $ri -lt $mri ]
 do
 mli=$((ri * sh_nthread + sh_nthread + 1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && zcat $sh_user/dbSNPnew/dbSNPnew.id.chr$li.gz | join -t "$tab" -e "." -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,2.1'  -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chr$li -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.newdbsnp.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
 zcat $sh_user/dbSNPnew/dbSNPnew.id.chrX.gz | join -t "$tab" -e "." -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,2.1'  -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chrX -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.newdbsnp.chrX&
 zcat $sh_user/dbSNPnew/dbSNPnew.id.chrY.gz | join -t "$tab" -e "." -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,2.1'  -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.nonewdbsnp.chrY -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.newdbsnp.chrY&
 wait

cd $sh_user/annovar


if [ ! -f $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt ]; then
[ ! -f $sh_outputdir/$1/exome/$1.indel.annovar ] && python $sh_user/vs_format_converter.py $sh_outputdir/$1/exome/somatic/$1.indel.Somatic | perl convert2annovar.pl --format vcf4 --includeinfo -allsample -withfreq stdin > $sh_outputdir/$1/exome/$1.indel.annovar || echo "$sh_outputdir/$1/exome/$1.indel.annovar exists."
perl table_annovar.pl $sh_outputdir/$1/exome/$1.indel.annovar humandb/ -buildver hg19 -out $sh_outputdir/$1/exome/$1.indel.table -thread $sh_nthread --maxgenethread $sh_nthread -remove -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,1000g2014oct_all,1000g2014oct_afr,1000g2014oct_eas,1000g2014oct_eur,clinvar_20150330,cosmic70,dbnsfp30a,exac03nontcga -operation g,r,r,f,f,f,f,f,f,f,f,f -nastring .
else
[ `head -n 1 $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt | awk -F '\t' '{print NF}'` -ne 61 ] && echo "\nWrong column number of $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt. Please delete the file and re-run." && exit
echo "$sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt exists."
fi

if [ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.txt ]; then
[ ! -f $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt ] && echo "$sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt not exists" && exit
cd $sh_outputdir/$1/exome/somatic/tmp
rm -f $1.indel.cosmic.id.chr* $1.indel.cosmic.chr*  
awk -F '\t' '($1 ~ /^chr..?$/) {print $1 "-" $2 $4 "-" $5 }' $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt | sort | awk -F '\t' '{print $1 >> "'"$1"'" ".indel.cosmic.id." substr($1, 1, index($1,"-")-1)}'
li=1
while [ $li -lt 23 ]
do
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chr$li ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chr$li
li=$((li+1))
done
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chrX ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chrX
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chrY ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chrY
cd $sh_outputdir/$1/exome
 li=1
 ri=0
 mli=1
 while [ $ri -lt $mri ]
 do
 mli=$((ri * sh_nthread + sh_nthread + 1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && zcat $sh_user/cosmic/cosmic.id.chr$li.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chr$li  -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
 zcat $sh_user/cosmic/cosmic.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chrX -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.chrX&
 zcat $sh_user/cosmic/cosmic.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.id.chrY -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.chrY&
 wait
cat $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.chr*  | sort -t "$tab" -k 2,2 > $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.txt
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.txt Finished"
else
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.txt exists!" 
fi

if [ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.txt ]; then
[ ! -f $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt ] && echo "$sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt not exists" && exit
cd $sh_outputdir/$1/exome/somatic/tmp
rm -f $1.indel.clinvar.id.chr* $1.indel.clinvar.chr*  
awk -F '\t' '($1 ~ /^chr..?$/) {print $1 "-" $2 $4 "-" $5 }' $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt | sort | awk -F '\t' '{print $1 >> "'"$1"'" ".indel.clinvar.id." substr($1, 1, index($1,"-")-1)}'
li=1
while [ $li -lt 23 ]
do
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chr$li ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chr$li
li=$((li+1))
done
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chrX ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chrX
[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chrY ] && touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chrY
cd $sh_outputdir/$1/exome
 li=1
 ri=0
 mli=1
 while [ $ri -lt $mri ]
 do
 mli=$((ri * sh_nthread + sh_nthread + 1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && zcat $sh_user/clinvar/clinvar.id.chr$li.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chr$li  -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
 zcat $sh_user/clinvar/clinvar.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chrX -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.chrX&
 zcat $sh_user/clinvar/clinvar.id.chrX.gz | join -t "$tab" -o '2.1,2.2' -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.id.chrY -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.chrY&
 wait
cat $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.chr*  | sort -t "$tab" -k 2,2 > $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.txt
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.txt Finished"
else
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.txt exists!" 
fi

cat $sh_outputdir/$1/exome/somatic/tmp/$1.indel.clinvar.txt $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.clinvar.txt | sort -t "$tab" -k 2,2 > $sh_outputdir/$1/exome/somatic/tmp/$1.clinvar.txt

cat $sh_outputdir/$1/exome/somatic/tmp/$1.indel.cosmic.txt $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.cosmic.txt | sort -t "$tab" -k 2,2 > $sh_outputdir/$1/exome/somatic/tmp/$1.cosmic.txt

rm -f $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chr* $sh_outputdir/$1/exome/somatic/tmp/$1.indel.newdbsnp.chr*
li=1
while [ $li -lt 23 ]
do
touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chr$li
li=$((li+1))
done
touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chrX
touch $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chrY

cat $sh_outputdir/$1/exome/$1.indel.table.hg19_multianno.txt | sed '1d' | awk -F '\t' '{print $1 "-" $2 $4 "-" $5 "\t" $0 }' | sort -t "$tab" -k 1,1 | awk -F '\t' '{print $0 >> "'"$sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp."'" substr($1, 1, index($1,"-")-1)}'

 li=1
 ri=0
 mli=1
 while [ $ri -lt $mri ]
 do
 mli=$((ri * sh_nthread + sh_nthread + 1))
 while [ $li -lt $mli ]
 do
 [ $li -lt 23 ] && zcat $sh_user/dbSNPnew/dbSNPnew.id.chr$li.gz | join -t "$tab" -e "." -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,2.1'  -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chr$li -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.newdbsnp.chr$li&
 li=$((li+1))
 done
 ri=$((ri+1))
 [ $ri -lt $mri ] && wait
 done
 zcat $sh_user/dbSNPnew/dbSNPnew.id.chrX.gz | join -t "$tab" -e "." -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,2.1'  -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chrX -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.newdbsnp.chrX&
 zcat $sh_user/dbSNPnew/dbSNPnew.id.chrY.gz | join -t "$tab" -e "." -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,2.1'  -1 1 $sh_outputdir/$1/exome/somatic/tmp/$1.indel.nonewdbsnp.chrY -2 2 - --nocheck-order >> $sh_outputdir/$1/exome/somatic/tmp/$1.indel.newdbsnp.chrY&
 wait

cat $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.newdbsnp.chr* | sort -t "$tab" -k 1,1 | join -t "$tab" -e "."  -1 1 - -2 2 $sh_outputdir/$1/exome/somatic/tmp/$1.clinvar.txt -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,2.1,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,1.63' | sort -t "$tab" -k 1,1 | join -t "$tab" -e "."  -1 1 - -2 2 $sh_outputdir/$1/exome/somatic/tmp/$1.cosmic.txt -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,2.1,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,1.63' | sed 's/\t\./\t/g' >  $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.tmp

cat $sh_outputdir/$1/exome/somatic/tmp/$1.indel.newdbsnp.chr* | sort -t "$tab" -k 1,1 | join -t "$tab" -e "."  -1 1 - -2 2 $sh_outputdir/$1/exome/somatic/tmp/$1.clinvar.txt -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,2.1,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,1.63' | sort -t "$tab" -k 1,1 | join -t "$tab" -e "."  -1 1 - -2 2 $sh_outputdir/$1/exome/somatic/tmp/$1.cosmic.txt -a 1 -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,2.1,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,1.63' | sed 's/\t\./\t/g' >>  $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.tmp
else
echo "$sh_outputdir/$1/exome/somatic/tmp/$1.somatic.tmp exists."
fi



[ ! -f $sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.txt ] && cat $sh_outputdir/$1/exome/somatic/$1.snp.Somatic | sed '1d' | awk -F '\t' '{if ($4 == "A" && $3 == "C") print $9 + $10 "\t" $10 "\t" $9 "\t" "0" "\t" "0" "\t" $24 "\t" $11/100; else if ($4 == "A" && $3 == "G") print $9 + $10 "\t" $10 "\t" "0" "\t" $9 "\t" "0" "\t" $24 "\t" $11/100; else if ($4 == "A" && $3 == "T") print $9 + $10 "\t" $10 "\t" "0" "\t" "0" "\t" $9 "\t" $24 "\t" $11/100; else if ($4 == "C" && $3 == "A")  print $9 + $10 "\t" $9 "\t" $10 "\t" "0" "\t" "0" "\t" $24 "\t" $11/100;  else if ($4 == "C" && $3 == "G")  print $9 + $10 "\t" "0" "\t" $10 "\t" $9 "\t" "0" "\t" $24 "\t" $11/100;  else if ($4 == "C" && $3 == "T")  print $9 + $10 "\t" "0" "\t" $10 "\t" "0" "\t" $9 "\t" $24 "\t" $11/100; else if ($4 == "G" && $3 == "A" ) print $9 + $10 "\t" $9 "\t" "0" "\t" $10 "\t" "0" "\t" $24 "\t" $11/100;  else if ($4 == "G" && $3 == "C" ) print $9 + $10 "\t" "0" "\t" $9 "\t" $10 "\t" "0" "\t" $24 "\t" $11/100;  else if ($4 == "G" && $3 == "T" ) print $9 + $10 "\t" "0" "\t" "0" "\t" $10 "\t" "9" "\t" $24 "\t" $11/100; else if ($4 == "T" && $3= "A") print $9 + $10 "\t" $9 "\t" "0" "\t" "0" "\t" $10 "\t" $24 "\t" $11/100; else if ($4 == "T" && $3 == "C") print $9 + $10 "\t" "0" "\t" "9" "\t" "0" "\t" $10 "\t" $24 "\t" $11/100; else if ($4 == "T" && $3 == "G") print $9 + $10 "\t" "0" "\t" "0" "\t" $9 "\t" $10 "\t" $24 "\t" $11/100}' > $sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.tmp && cat $sh_outputdir/$1/exome/somatic/$1.indel.Somatic | sed '1d' | awk -F '\t' '{print $9 + $10 "\t" "0" "\t" "0" "\t" "0" "\t" "0" "\t" $24 "\t" $11/100}' >> $sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.tmp && cat $sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.tmp | sed 's/%//g' | sort -t "$tab" -u -k6,6 > $sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.txt || echo "$sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.txt exists!\n"

echo 'id\tChr\tStart\tEnd\tRef\tAlt\tFunc.refGene\tGene.refGene\tGeneDetail.refGene\tExonicFunc.refGene\tAAChange.refGene\tcytoBand\tgenomicSuperDups\tesp6500siv2_all\t1000g2014oct_all\t1000g2014oct_afr\t1000g2014oct_eas\t1000g2014oct_eur\tclinvar\tcosmic\tSIFT_score\tSIFT_pred\tPolyphen2_HDIV_score\tPolyphen2_HDIV_pred\tPolyphen2_HVAR_score\tPolyphen2_HVAR_pred\tLRT_score\tLRT_pred\tMutationTaster_score\tMutationTaster_pred\tMutationAssessor_score\tMutationAssessor_pred\tFATHMM_score\tFATHMM_pred\tPROVEAN_score\tPROVEAN_pred\tVEST3_score\tCADD_raw\tCADD_phred\tDANN_score\tfathmm-MKL_coding_score\tfathmm-MKL_coding_pred\tMetaSVM_score\tMetaSVM_pred\tMetaLR_score\tMetaLR_pred\tintegrated_fitCons_score\tintegrated_confidence_value\tGERP++_RS\tphyloP7way_vertebrate\tphyloP20way_mammalian\tphastCons7way_vertebrate\tphastCons20way_mammalian\tSiPhy_29way_logOdds\tExAC_nontcga_ALL\tExAC_nontcga_AFR\tExAC_nontcga_AMR\tExAC_nontcga_EAS\tExAC_nontcga_FIN\tExAC_nontcga_NFE\tExAC_nontcga_OTH\tExAC_nontcga_SAS\tdbsnpnew\ttotal_read\tA_read\tC_read\tG_read\tT_read\tratio'> $sh_outputdir/$1/exome/$1.somatic.txt

cat $sh_outputdir/$1/exome/somatic/tmp/$1.somatic.tmp | sort -t "$tab" -k1,1 | join -t "$tab" -e "."  -a 1 -1 1 - -2 6 $sh_outputdir/$1/exome/somatic/tmp/$1.rc.id.txt -o '0,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,1.10,1.11,1.12,1.13,1.14,1.15,1.16,1.17,1.18,1.19,1.20,1.21,1.22,1.23,1.24,1.25,1.26,1.27,1.28,1.29,1.30,1.31,1.32,1.33,1.34,1.35,1.36,1.37,1.38,1.39,1.40,1.41,1.42,1.43,1.44,1.45,1.46,1.47,1.48,1.49,1.50,1.51,1.52,1.53,1.54,1.55,1.56,1.57,1.58,1.59,1.60,1.61,1.62,1.63,2.1,2.2,2.3,2.4,2.5,2.7' --nocheck-order | sed 's/\t\./\t/g'| sort -t "$tab" -k1,1 >> $sh_outputdir/$1/exome/$1.somatic.txt
echo "$sh_outputdir/$1/exome/$1.somatic.txt done!\n"
else
echo "\n$sh_outputdir/$1/exome/$1.somatic.txt exists!\n"
fi


cd $sh_outputdir/$1/exome

[ ! -f $1.somatic.exonic.maf  ] && echo "Chromosome\tStart_Position\tEnd_Position\tReference_Allele\tTumor_Seq_Allele1\tTumor_Seq_Allele2\tHugo_Symbol\tVariant_Classification\tid\tTumor_Sample_Barcode" > $1.somatic.exonic.maf && cat $1.somatic.txt | awk -F '\t' '$7 == "exonic" {print}' | sed 's/nonframeshift deletion/In_Frame_Del/g' | sed 's/nonframeshift insertion/In_Frame_Ins/g' | sed 's/frameshift deletion/Frame_Shift_Del/g' | sed 's/frameshift insertion/Frame_Shift_Ins/g' | sed 's/nonsynonymous SNV/Missense_Mutation/g' | sed 's/stopgain/Nonsense_Mutation/g' | sed 's/stoploss/Nonstop_Mutation/g' | sed 's/synonymous SNV/Silent/g' | sed "s/UTR3/3'UTR/g" | sed "s/UTR5/5'UTR/g" | sed 's/ncRNA_exonic;splicing/Non-coding_Transcript/g' | sed 's/ncRNA_intronic/Non-coding_Transcript/g' | sed 's/ncRNA_splicing/Non-coding_Transcript/g' | sed 's/intergenic/IGR/g' | sed 's/intronic/Intron/g' | sed 's/ncRNA_exonic/Non-coding_Transcript/g' | sed 's/ncRNA_exonic;splicing/Non-coding_Transcript/g' | sed 's/ncRNA_intronic/Non-coding_Transcript/g' | sed 's/ncRNA_splicing/Non-coding_Transcript/g' | sed 's/intronic/Intron/g' | sed 's/splicing/Splice_Site/g' | sed 's/unknown/NA/g' | awk -F '\t' '{print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $6 "\t" $8 "\t" $10 "\t" $1 "\t" "'"$1"'" }' | sort -t "$tab" -k9,9  >> $1.somatic.exonic.maf || echo "$sh_outputdir/$1/exome/$1.somatic.exonic.maf exists!\n"

[ ! -f $1.somatic.exonic.nodb.maf  ] && echo "Chromosome\tStart_Position\tEnd_Position\tReference_Allele\tTumor_Seq_Allele1\tTumor_Seq_Allele2\tHugo_Symbol\tVariant_Classification\tid\tTumor_Sample_Barcode" > $1.somatic.exonic.nodb.maf && cat $1.somatic.txt | awk -F '\t' '$7 == "exonic" {print}' | sed '/rs/d' | sed 's/nonframeshift deletion/In_Frame_Del/g' | sed 's/nonframeshift insertion/In_Frame_Ins/g' | sed 's/frameshift deletion/Frame_Shift_Del/g' | sed 's/frameshift insertion/Frame_Shift_Ins/g' | sed 's/nonsynonymous SNV/Missense_Mutation/g' | sed 's/stopgain/Nonsense_Mutation/g' | sed 's/stoploss/Nonstop_Mutation/g' | sed 's/synonymous SNV/Silent/g' | sed "s/UTR3/3'UTR/g" | sed "s/UTR5/5'UTR/g" | sed 's/ncRNA_exonic;splicing/Non-coding_Transcript/g' | sed 's/ncRNA_intronic/Non-coding_Transcript/g' | sed 's/ncRNA_splicing/Non-coding_Transcript/g' | sed 's/intergenic/IGR/g' | sed 's/intronic/Intron/g' | sed 's/ncRNA_exonic/Non-coding_Transcript/g' | sed 's/ncRNA_exonic;splicing/Non-coding_Transcript/g' | sed 's/ncRNA_intronic/Non-coding_Transcript/g' | sed 's/ncRNA_splicing/Non-coding_Transcript/g' | sed 's/intronic/Intron/g' | sed 's/splicing/Splice_Site/g' | sed 's/unknown/NA/g' | awk -F '\t' '{print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $6 "\t" $8 "\t" $10 "\t" $1 "\t" "'"$1"'" }' | sort -t "$tab" -k9,9 >> $1.somatic.exonic.nodb.maf  || echo "$sh_outputdir/$1/exome/$1.somatic.exonic.nodb.maf exists!\n"


case "$* " in
 *" -kt "*)
 ;;
 *)
 rm -f $sh_outputdir/$1/exome/mpileup/$1.chr*.snp $sh_outputdir/$1/exome/mpileup/$1.chr*.indel 
 rm -rf $sh_outputdir/$1/exome/somatic/tmp
 ;;
esac

case "$* " in
 *" -s "*)
 echo "\nIf password is asked for shutdown, run sudo visudo and add the following line:\n\nuser(your username) ALL=(ALL) NOPASSWD: /sbin/shutdown\n\n"
 sudo shutdown -h now
 ;;
esac

