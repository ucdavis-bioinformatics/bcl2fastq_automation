#!/bin/bash

#SBATCH --array=1-8
#SBATCH --job-name=bcl2fastq # Job name
#SBATCH --nodes=1
#SBATCH --time=180
#SBATCH --cpus-per-task=24 # Number of cores
#SBATCH --mem=8000 # Memory pool for all cores (see also --mem-per-cpu)

start=`date +%s`
hostname
echo "My SLURM_JOB_ID"
echo $SLURM_JOB_ID

module load bcl2fastq

runfolder=$1
outfolder=$2

echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
samplesheet=`sed "${SLURM_ARRAY_TASK_ID}q;d" ${runfolder}/all_sample_sheets.txt`

projectfolder=${samplesheet%.SampleSheet.csv}

run_bcl2fastq.pl $runfolder/RunInfo.xml $samplesheet $runfolder $outfolder

if [ $? -ne 0 ]
then
    touch ${runfolder}/flags/error_flag$SLURM_ARRAY_TASK_ID
fi

cp ${samplesheet} ${projectfolder}
touch ${runfolder}/flags/done_flag$SLURM_ARRAY_TASK_ID

end=`date +%s`
runtime=$((end-start))
echo $runtime
