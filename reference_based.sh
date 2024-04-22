#!/bin/bash

echo "********** Quality Control Check ************"
echo "Do you want to install fastqc (y/n)??"
read choice1

if [[ "$choice1" =~ [yY] ]]; then  
    sudo apt install fastqc
elif [[ "$choice1" =~ [nN] ]]; then  
    echo "Skipping fastqc installation"
else
    echo "Invalid input. Please enter 'y' or 'n'."  # Added else clause
fi

mkdir fastqc_result

echo " Carefully provide the accession number your fastq file [e.g. SRR1234567]"
read fastq
fastqc -o fastqc_result -t 2 "$fastq"*.fastq


echo "Enter the name of the reference genome file [fasta file]"
read reference



echo "******** Trimming the fastq files: **********"

echo "Do you want to install trimmomatic (y/n) ??"
read trimmomatic
if [[ "$trimmomatic" =~ [yY] ]]; then  
    sudo apt install trimmomatic
elif [[ "$trimmomatic" =~ [nN] ]]; then  
    echo "Skipping trimmomatic installation"
else
    echo "Invalid input. Please enter 'y' or 'n'."  # Added else clause
fi

mkdir trimmomatic
TrimmomaticPE -phred33 "$fastq"_1.fastq "$fastq"_2.fastq -baseout trimmomatic/trimmed_"$fastq".fastq LEADING:15 TRAILING:15 SLIDINGWINDOW:4:25 MINLEN:36
echo "Trimming completes succesfully"

#trimmomatic PE -phred33 SRR27199327_1P.fastq SRR27199327_2P.fastq trimmed_R1.fastq unpaired_R1.fastq trimmed_R2.fastq unpaired_R2.fastq LEADING:20 TRAILING:20 SLIDINGWINDOW:4:30 MINLEN:36
#why its not working


echo "**** quality control on trimmed data ******"
cd trimmomatic
mkdir trimmed_fastqc_result
fastqc -o trimmed_fastqc_result -t 2 trimmed_"$fastq"*P.fastq



echo "********** Indexing reference genome *********"

echo "Download the refernce genome from genome database"
echo "carefully copy the reference genome fasta file in the 'trimmomatic' directory"
echo "if the reference an fna file, rename it as a fasta file  [e.g reference.fna --> reference.fasta]"



bwa index "$reference"

echo "aligning the trimmed files with the reference genome"
bwa mem -t 4 "$reference" trimmed_"$fastq"_1P.fastq trimmed_"$fastq"_2P.fastq > aligned.sam
echo "#### the aligned SAM file has been created successfully ###"

echo "Do you want to install samtools (y/n) ??"
read samtools
if [[ "$samtools" =~ [yY] ]]; then  
    sudo apt install samtools
elif [[ "$samtools" =~ [nN] ]]; then  
    echo "Skipping samtools installation"
else
    echo "Invalid input. Please enter 'y' or 'n'."  # Added else clause
fi



echo "Coverting the aligned SAM file to BAM file"
samtools view -bS aligned.sam > aligned.bam
echo "### BAM file has been created successfully ###"

echo "Sorting the BAM file"
samtools sort -o sorted.bam aligned.bam


echo "Indexing the sorted BAM file"
samtools index sorted.bam

echo  "******** final assembled genome *********"
samtools fasta -o final_assembly.fasta sorted.bam
echo "Thank you!"