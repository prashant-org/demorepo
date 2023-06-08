#!/bin/sh

# defuse.sh
# Author: Chin-Chen Pan
# Directore, General and Surgical Pathology
# Professor, attending pathologist
# Department of Pathology and Laboratory Medicine
# Taipei Veterans General Hospital
# TAIWAN
# Version 1.3.1
# Date: Feb 21, 2018

[ ! -f ./defuse.config ] && echo "defuse.config not exists.\n" && exit

read sh_user sh_inputdir sh_outputdir sh_thread < ./defuse.config

echo "\nUser path: $sh_user\nInput path: $sh_inputdir\nOutput path: $sh_outputdir\nThread number: $sh_thread\n"

if [ ! -f /usr/local/bin/gmap ]; then
[ ! -d $sh_user/gmap-2016-06-30 ] && echo "\nPlease check all of the followings are present: \n\n$sh_user/gmap-2016-06-30\n" && exit
cd $sh_user/gmap-2016-06-30
./configure
sudo make
sudo make install
fi

[ $# -lt 2 ] && echo '\nToo few arguments!\n\nArgument1 (required): Sample name\nArgument2 (required): Suffix (fq/fastq/fq.gz/fastq.gz)\nOptions:\n  -df2: use second configuration file for SOAPfuse\n  -s: shutdown after finished\n' && exit

[ "$2" != "fq.gz" -a "$2" != "fastq.gz" -a "$2" != "fq" -a "$2" != "fastq" ] && echo "\n\nInvalid input suffix: $2...Please use one of fq/fastq/fq.gz/fastq.gz\n\n" && exit

kt=0

case "$* " in
 *" -kt "*)
 kt=1
 ;;
esac

sh_inputfile1="$sh_inputdir/$1/Lib/$1_1.$2"
sh_inputfile2="$sh_inputdir/$1/Lib/$1_2.$2"

[ ! -f $sh_inputfile1 -o ! -f $sh_inputfile2 ] && echo "\n$sh_inputfile1 or $sh_inputfile2 NOT EXIST!\n" && exit

[ ! -d $sh_user/defuse ] && echo "\n$sh_user/defuse not present!\n" && exit

[ ! -d $sh_user/defuse_ref/gmap ] && cat $sh_user/defuse/scripts/config.txt | sed "s|= *samtools *$|= $sh_user\/defuse\/bin\/samtools|g" | sed "s|= *bowtie *$|= $sh_user\/defuse\/bin\/bowtie|g" | sed "s|= *bowtie-build *$|= $sh_user\/defuse\/bin\/bowtie-build|g" | sed "s|= *blat *$|= $sh_user\/defuse\/bin\/blat|g" | sed "s|= *faToTwoBit *$|= $sh_user\/defuse\/bin\/faToTwoBit|g" > $sh_user/defuse/scripts/configr.txt && cd $sh_user/defuse/scripts && perl defuse_create_ref.pl -d $sh_user/defuse_ref -c $sh_user/defuse/scripts/configr.txt && rm -f $sh_user/defuse/scripts/configr.txt

mkdir -p $sh_outputdir/$1/defuse

echo "# Author: Chin-Chen Pan\n# Directore, General and Surgical Pathology\n# Professor, attending pathologist\n# Department of Pathology and Laboratory Medicine\n# Taipei Veterans General Hospital\n# TAIWAN\n# Version 1.3.1\n\nUser path: $sh_user\nInput path: $sh_inputdir\nOutput path: $sh_outputdir\nThread number: $sh_thread\nInputfile1: $sh_inputfile1\nInputfile2: $sh_inputfile2\n\nArguments: $*\n" > $sh_outputdir/$1/defuse/deFuse.log



echo ================================================
echo Run deFuse 
echo ================================================
echo "deFuse started: `date '+%c'`" >> $sh_outputdir/$1/defuse/deFuse.log
if [ ! -f $sh_outputdir/$1/defuse/results.filtered.tsv ]; then
rm -rf $sh_outputdir/$1/defuse/tmp
mkdir -p $sh_outputdir/$1/defuse/tmp
case "$* " in
  *" -df2 "*)
  [ ! -f $sh_user/defuse/scripts/config2.txt ] && echo "\n$sh_user/defuse/scripts/config2.txt not exists. Create one with different parameters." | tee -a $sh_outputdir/$1/defuse/deFuse.log && exit
  cat $sh_user/defuse/scripts/config2.txt | sed "s|= *samtools *$|= $sh_user\/defuse\/bin\/samtools|g" | sed "s|= *bowtie *$|= $sh_user\/defuse\/bin\/bowtie|g" | sed "s|= *bowtie-build *$|= $sh_user\/defuse\/bin\/bowtie-build|g" | sed "s|= *blat *$|= $sh_user\/defuse\/bin\/blat|g" | sed "s|= *faToTwoBit *$|= $sh_user\/defuse\/bin\/faToTwoBit|g" > $sh_outputdir/$1/defuse/config.txt
  ;;
  *)
  cat $sh_user/defuse/scripts/config.txt | sed "s|= *samtools *$|= $sh_user\/defuse\/bin\/samtools|g" | sed "s|= *bowtie *$|= $sh_user\/defuse\/bin\/bowtie|g" | sed "s|= *bowtie-build *$|= $sh_user\/defuse\/bin\/bowtie-build|g" | sed "s|= *blat *$|= $sh_user\/defuse\/bin\/blat|g" | sed "s|= *faToTwoBit *$|= $sh_user\/defuse\/bin\/faToTwoBit|g" > $sh_outputdir/$1/defuse/config.txt
  ;;
 esac
cd $sh_user/defuse/scripts
if [ "$2" = "fq.gz" -o "$2" = "fastq.gz" ]; then
rm -f $sh_outputdir/$1/defuse/tmp/$1_1.fastq
rm -f $sh_outputdir/$1/defuse/tmp/$1_2.fastq
mkfifo $sh_outputdir/$1/defuse/tmp/$1_1.fastq
mkfifo $sh_outputdir/$1/defuse/tmp/$1_2.fastq
zcat $sh_inputfile1 > $sh_outputdir/$1/defuse/tmp/$1_1.fastq & zcat $sh_inputfile2 > $sh_outputdir/$1/defuse/tmp/$1_2.fastq & perl defuse_run.pl -d $sh_user/defuse_ref -1 $sh_outputdir/$1/defuse/tmp/$1_1.fastq -2 $sh_outputdir/$1/defuse/tmp/$1_2.fastq -o $sh_outputdir/$1/defuse/tmp -p $sh_thread -l $sh_outputdir/$1/defuse/tmp -c $sh_outputdir/$1/defuse/config.txt
rm -f $sh_outputdir/$1/defuse/tmp/$1_1.fastq
rm -f $sh_outputdir/$1/defuse/tmp/$1_2.fastq
else
perl defuse_run.pl -d $sh_user/defuse_ref -1 $sh_inputfile1 -2 $sh_inputfile2 -o $sh_outputdir/$1/defuse/tmp -p $sh_thread -l $sh_outputdir/$1/defuse/tmp -c $sh_outputdir/$1/defuse/config.txt
fi
[ ! -f $sh_outputdir/$1/defuse/tmp/results.filtered.tsv ] && echo "Creat results.filtered.tsv failed.\nDelete this file if you want to rerun deFuse." > $sh_outputdir/$1/defuse/tmp/results.filtered.tsv
mv -f $sh_outputdir/$1/defuse/tmp/*.tsv $sh_outputdir/$1/defuse
else
echo "$sh_outputdir/$1/defuse/results.filtered.tsv exists!" | tee -a $sh_outputdir/$1/defuse/deFuse.log 
fi
echo "deFuse finished: `date '+%c'`\n" >> $sh_outputdir/$1/defuse/deFuse.log
[ $kt -eq 0 ] && rm -rf $sh_outputdir/$1/defuse/tmp

cd ~

case "$* " in
 *" -s "*)
 echo "\nIf password is asked for shutdown, run sudo visudo and add the following line:\n\nuser(your username) ALL=(ALL) NOPASSWD: /sbin/shutdown\n\n"
 sudo shutdown -h now
 ;;
esac



