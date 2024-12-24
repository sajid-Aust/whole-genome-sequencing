#!/bin/bash
#fastq-dump SRR600 --split-files --skip-technical
echo " Bacterial Genome Assembly and Annotation "
## Quality Control
echo "** Quality Control Check **"

mkdir fastqc_result
echo "Carefully provide the accession number or the name of your fastq file within the 'sra' directory [e.g. SRR1234567, DC-3 from DC-3_1.fq]"
read fastq
fastqc -o fastqc_result -t 2 ./sra/"$fastq"*.fq

echo "* Trimming the fastq files: ***"

mkdir trimgalore

conda activate wgs

trim_galore --paired --quality 25 --length 36 --clip_R1 15 --clip_R2 15 --output_dir trimgalore/ ./sra/"$fastq"_1.fq ./sra/"$fastq"_2.fq


echo "Trimming completes succesfully"



# De Novo Assembly using unicycler
echo "** assembly using unicycler **"

#spades for assembly
mkdir assembly_output
spades.py -t 64 -1 ./trimgalore/*_1.fq -2 ./trimgalore/*_2.fq -o assembly_output

cp ./assembly_output/contigs.fasta ./

cp ./assembly_output/scaffolds.fasta ./
## Genome annotation
echo "** Genome Annotation **"

echo "guessing you have prokka installed!"
#prokka --outdir final_prokka --genus 'Name' --species 'name' assembly_output/contigs.fasta

if [ -f assembly_output/contigs.fasta ]; then
    prokka --outdir annotated_genome --kingdom bacteria --cpus 190 --prefix annotated_genome --locustag annotated_genome assembly_output/contigs.fasta
    echo "Prokka command with contigs.fasta executed successfully."
else
    prokka --outdir annotated_genome --kingdom bacteria --cpus 190 --prefix annotated_genome --locustag annotated_genome assembly_output/scaffolds.fasta
    echo "Prokka command with scaffolds.fasta executed successfully."
fi

echo "** Analysis Complete **"

echo "Thank you!"

# ------------------------------------------------------------------------ #
#                      Added QUAST and File Copying                       #
# ------------------------------------------------------------------------ #

# Run QUAST for assembly evaluation

if [ -f assembly_output/contigs.fasta ]; then
    quast.py assembly_output/contigs.fasta -o quast_evaluation_result
    echo "QUAST command with contigs.fasta executed successfully."
else
    quast.py assembly_output/scaffolds.fasta -o quast_evaluation_result
    echo "QUAST command with scaffolds.fasta executed successfully."
fi
# Create directory for NCBI submission materials
mkdir NCBI_submission_materials

# Copy relevant files to the NCBI submission directory
cp ./assembly_output/contigs.fasta ./NCBI_submission_materials
cp ./assembly_output/scaffolds.fasta ./NCBI_submission_materials
cp -r ./annotated_genome/annotated_genome.faa ./annotated_genome/annotated_genome.gbk ./annotated_genome/annotated_genome.sqn ./annotated_genome/annotated_genome.txt ./NCBI_submission_materials  
cp -r ./quast_evaluation_result/icarus_viewers ./quast_evaluation_result/report.html ./quast_evaluation_result/report.pdf ./NCBI_submission_materials

echo "Thank you!"
