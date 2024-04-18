#!/bin/bash

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
echo "your qc report is available now."
cd fastqc_result
echo " press 'y' to see the both quality report"
read qc_report
if [[ "$qc_report" =~ [yY] ]]; then 
	google-chrome "$fastq"*.html
fi
cd ..


echo "Trimming the fastq files:"
mkdir trimmomatic
echo "Do you want to install trimmomatic (y/n) ??"
read trimmomatic
if [[ "$trimmomatic" =~ [yY] ]]; then  
    sudo apt install trimmomatic
elif [[ "$trimmomatic" =~ [nN] ]]; then  
    echo "Skipping trimmomatic installation"
else
    echo "Invalid input. Please enter 'y' or 'n'."  # Added else clause
fi

TrimmomaticPE -phred33 "$fastq"_1.fastq "$fastq"_2.fastq -baseout trimmomatic/trimmed_"$fastq".fastq LEADING:15 TRAILING:15 SLIDINGWINDOW:4:25 MINLEN:36
echo "Trimming completes succesfully"

echo "Lets start the genome assembly"
cd trimmomatic
echo "Do you want to install spades (y/n) ??"
read spades

if [[ "$spades" =~ [yY] ]]; then  
    sudo apt install spades
elif [[ "$spades" =~ [nN] ]]; then  
    echo "Skipping spades installation"
else
    echo "Invalid input. Please enter 'y' or 'n'."  # Added else clause
fi

#spades.py -1 *_1P.fastq -2 *_2P.fastq -o assembly_output
spades.py -1 trimmomatic/*_1P.fastq -2 trimmomatic/*_2P.fastq -o assembly_output

echo "genome assemble successful."

echo "guessing you have prokka installed!"
conda activate prokka
#prokka --outdir final_prokka --genus 'Name' --species 'name' assembly_output/contigs.fasta

if [ -f assembly_output/contigs.fasta ]; then
    prokka --outdir final_prokka --genus 'Name' --species 'name' assembly_output/contigs.fasta
    echo "Prokka command with contigs.fasta executed successfully."
else
    prokka --outdir final_prokka --genus 'Name' --species 'name' assembly_output/scaffolds.fasta
    echo "Prokka command with scaffolds.fasta executed successfully."
fi

conda deactivate

echo "**** antibiotic resistance surveillance using CCtyper ****"
conda activate cctyper
cctyper assembly_output/contigs.fasta cctyper_output
conda deactivate

echo "*** antimicrobial resistance identifiation by abricate ******"
conda activate abricate
mkdir abricate_output
abricate assembly_output/contigs.fasta > abricate_output/abricate_output.txt
conda deactivate

echo "Thank you!!!"








