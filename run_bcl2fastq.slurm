#!/bin/bash

#SBATCH --job-name=bcl2fastq # Job name
#SBATCH --nodes=1
#SBATCH --time=180
#SBATCH --cpus-per-task==24 # Number of cores
#SBATCH --mem=8000 # Memory pool for all cores (see also --mem-per-cpu)

start=`date +%s`

hostname

echo "My SLURM_JOB_ID"
echo $SLURM_JOB_ID

module load bcl2fastq

samplesheet=$1
runfolder=$2
outfolder=$3
projectfolder=$4;
mismatch=$5
basemask=$6

call="bcl2fastq \
--sample-sheet ${samplesheet} \
--runfolder-dir ${runfolder} \
--output-dir ${outfolder} \
--stats-dir ${projectfolder}/Stats \
--reports-dir ${projectfolder}/Reports \
--create-fastq-for-index-reads \
--ignore-missing-positions \
--ignore-missing-controls \
--ignore-missing-filter \
--ignore-missing-bcls \
--barcode-mismatches ${mismatch} \
--loading-threads 2 \
--demultiplexing-threads 6 \
--processing-threads 14 \
--writing-threads 2 \
--use-bases-mask ${basemask}"

echo $call
eval $call

cp ${samplesheet} ${projectfolder}

touch ${runfolder}/done_flag

end=`date +%s`

runtime=$((end-start))

echo $runtime
