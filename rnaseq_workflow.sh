
######### rnaseq_workflow.sh ###################

#!/bin/bash

echo "Usage: rnaseq_workflow.sh <run name> <lane numbers> <source directory> <analysis directory> <genome data path> <genome name>"


module load bio/fastqc-0.10.0

module load hpc/python-2.7

module load bio/tophat-2.0.7.Linux_x86_64

module load bio/samtools-0.1.18_zlib-1.2.5

module load bio/Trimmomatic-0.27



RUN=$1
LANES=$2
SOURCEDIR=$3
WORKDIR=$4
GENOMEPATH=$5
GENOME=$6



## Create run directory and copy lane data from /n/ngsdata

mkdir $WORKDIR/$RUN

echo -e "\nRun: $RUN \n\n" >> $WORKDIR/$RUN.log.txt

for lane in `echo $LANES`;  
do  
  echo "Copying lane$lane from nsgdata " >> $WORKDIR/$RUN.log.txt
  ls -lt $SOURCEDIR/$RUN/BclToFastq_lane$lane\_*;  
  scp -r $SOURCEDIR/$RUN/BclToFastq_lane$lane\_* $WORKDIR/$RUN
done


## Process reads with FastQC, Trimmomatic, Tophat 

cd $WORKDIR/$RUN

for lane in `echo $LANES`;
do

  FASTQCDIR=BclToFastq_lane$lane\_1/FastQC
  mkdir $FASTQCDIR
  TRIMDIR=BclToFastq_lane$lane\_1/Trimmomatic
  mkdir $TRIMDIR

  cd BclToFastq_lane$lane\_1/Project_*

  echo -e "\n\n\nProcessing lane$lane" >> $WORKDIR/$RUN.log.txt


  for library in `ls Sample*R1.fastq.gz`;
  do

    stem=`echo $library | sed -e 's/^Sample_//' -e 's/\.R1\.fastq\.gz$//'`
    echo -e "\n\n*** Processing library: $stem" >> $WORKDIR/$RUN.log.txt

    echo -e "\n\n>>FastQC<<" >> $WORKDIR/$RUN.log.txt
    fastqc_stem=`echo $library | sed -e 's/\.fastq\.gz$//'`

    echo -e "Input: $library \nOutput: ${fastqc_stem}_fastqc.zip" >> $WORKDIR/$RUN.log.txt
    echo -e "Command: fastqc -o $WORKDIR/$RUN/$FASTQCDIR -t 6 --casava --noextract --nogroup $library" >> $WORKDIR/$RUN.log.txt
    echo -e "Start-time: `date` "  >> $WORKDIR/$RUN.log.txt
    fastqc -o $WORKDIR/$RUN/$FASTQCDIR -t 6 --casava --noextract --nogroup $library &> /dev/null
    echo -e "End-time: `date` "  >> $WORKDIR/$RUN.log.txt


    echo -e "\n\n>>Trimmomatic<<" >> $WORKDIR/$RUN.log.txt

    echo -e "Input: $library \nOutput: $fastqc_stem.trim.fastq.gz" >> $WORKDIR/$RUN.log.txt
    echo -e "Command: java -jar /n/sw/Trimmomatic-0.27/trimmomatic-0.27.jar  SE -phred33 $library $WORKDIR/$RUN/$TRIMDIR/$fastqc_stem.trim.fastq.gz ILLUMINACLIP:$HOME/bin/TruSeq_all.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36"  >> $WORKDIR/$RUN.log.txt
    echo -e "Start-time: `date` "  >> $WORKDIR/$RUN.log.txt
    java -jar /n/sw/Trimmomatic-0.27/trimmomatic-0.27.jar  SE -phred33 $library $WORKDIR/$RUN/$TRIMDIR/$fastqc_stem.trim.fastq.gz ILLUMINACLIP:$HOME/bin/TruSeq_all.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    echo -e "End-time: `date` "  >> $WORKDIR/$RUN.log.txt


    echo -e "\n\n>>Tophat<<" >> $WORKDIR/$RUN.log.txt

    echo -e "Input: $library \nOutput: tophat_$stem" >> $WORKDIR/$RUN.log.txt
    echo -e "Command: tophat -G $GENOMEPATH/genes.gtf -o tophat_$stem --no-coverage-search $GENOMEPATH/$GENOME $library"  >> $WORKDIR/$RUN.log.txt
    echo -e "Start-time: `date` "  >> $WORKDIR/$RUN.log.txt
    #tophat -G $GENOMEPATH/genes.gtf -o tophat_$stem --no-coverage-search $GENOMEPATH/$GENOME $library
    tophat -p 8 -o tophat_$stem --no-coverage-search $GENOMEPATH/$GENOME $library
    echo -e "End-time: `date` "  >> $WORKDIR/$RUN.log.txt


    #samtools index tophat_$stem/accepted_hits.bam

  done 

  cd ../..

done

echo -e "\n\n"  >> $WORKDIR/$RUN.log.txt


#############################################

