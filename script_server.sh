#!/bin/bash
#fastq-dump SRR600 --split-files --skip-technical
echo " Bacterial Genome Assembly and Annotation "
## Quality Control

mkdir fastqc_result
echo "Carefully provide the accession number of your fastq file within the 'sra' directory [e.g. DC-3 from DC-3_1.fq]"
read fastq
fastqc -o fastqc_result -t 32 "$fastq"*.fq

echo "* Trimming the fastq files: ***"
mkdir trimgalore


trim_galore --paired --quality 25 --length 36 --clip_R1 15 --clip_R2 15 --output_dir trimgalore/ "$fastq"_1.fq "$fastq"_2.fq

echo "Trimming completes succesfully"

# De Novo Assembly using unicycler
echo "** assembly using unicycler **"

mkdir assembly_output
#update the unicycler if found any spades compatibility issue within it.
unicycler -1 ./trimgalore/*_1.fq -2 ./trimgalore/*_2.fq -o assembly_output -t 64

## Genome annotation
echo "** Genome Annotation **"

# Perform genome annotation using Prokka
echo "** Running Prokka annotation (please wait...) **"
prokka --outdir annotated_genome --kingdom bacteria --cpus 64 --prefix annotated_genome --locustag annotated_genome ./assembly_output/assembly.fasta

echo "** Analysis Complete **"

echo "Thank you!"

# ------------------------------------------------------------------------ #
#                      Added QUAST and File Copying                       #
# ------------------------------------------------------------------------ #

# Run QUAST for assembly evaluation
quast.py ./assembly_output/assembly.fasta -o quast_evaluation_result

# Create directory for NCBI submission materials
mkdir NCBI_submission_materials

# Copy relevant files to the NCBI submission directory
cp ./assembly_output/assembly.fasta ./NCBI_submission_materials
cp -r ./annotated_genome/annotated_genome.faa ./annotated_genome/annotated_genome.gbk ./annotated_genome/annotated_genome.sqn ./annotated_genome/annotated_genome.txt ./NCBI_submission_materials  
cp -r ./quast_evaluation_result/icarus_viewers ./quast_evaluation_result/report.html ./quast_evaluation_result/report.pdf ./NCBI_submission_materials

echo "Thank you!"
