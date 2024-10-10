#!/bin/bash                                                                     
#:Title: "Nanopore assembly example workflow"                                                      
#:Date: 09-10-2024                                                             
#:Author: "Gerald Moreno-Morales"                           
#:Version: 1.0                                                                 
#:Description : Procesamiento de fastq de Nanopore long reads y ensamblaje para el curso de Bioinformatica aplicada a la salud         
#:Options: None  


#Se descargara la herramienta sratools para descargar de manera automatica
#1 archivo crudo de NCBI (sra)

cd /home/ubigem/Documentos/gerald_docs/tareas/bioinfo_ensamblaje
ls
wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.1.1/sratoolkit.3.1.1-ubuntu64.tar.gz
chmod +x stk.tar.gz #activar permisos
tar -vxzf stk.tar.gz  #descomprimir

echo 'export PATH=$PATH:~/Documentos/gerald_docs/tareas/bioinfo_ensamblaje/sratoolkit.3.1.1-ubuntu64/bin' >> ~/.bashrc
source ~/.bashrc
prefetch #comprobar que el directorio bin se encuentre en el path

nano SRR30734833.txt #Pegas la lista de sra que deseas bajar
prefetch --max-size 50G --option-file SRR30734833.txt
cp SRR30734833/SRR30734833.sra .
rm -r SRR30734833/
fasterq-dump --split-files *.sra #separar en forward y reverse;

rm -r SRR30734833  ##Borrar las carpetas pero con cuidado

#OUTPUT: SRR30734833.sra 

###############################
###Calidad de reads: Nanoplot##
###############################

conda activate nanoplot
#conda install openssl=1.0
#conda list openssl
#conda install -c bioconda pysam
pip install NanoPlot --upgrade

NanoPlot --fastq SRR30734833.fastq -t 9 -o SRR30734833
conda deactivate

scp 
#OUTPUT: 

#####################################
##Remocion de adaptadores: Porechop##
#####################################

porechop -i SRR30734833.fastq -o SRR30734833_adpt_out.fastq


#OUTPUT: 22,969 / 30,273 reads had adapters trimmed from their end (1,226,574 bp removed)
# 87 / 30,273 reads were split based on middle adapters

##################################
##Filtrado por calidad: Nanofilt##
##################################


conda create --name NanoFilt
conda activate NanoFilt

conda install bioconda::nanofilt
pip install nanofilt --upgrade

NanoFilt SRR30734833_adpt_out.fastq -q 10 | gzip > SRR30734833_highQuality-reads.fastq.gz

#OUTPUT: SRR30734833_highQuality-reads.fastq.gz

#####################
##Ensamblaje:Flye####
#####################

conda create --name flye
conda activate flye
conda install bioconda::flye

flye --nano-raw SRR30734833_highQuality-reads.fastq.gz --genome-size 2.8m --out-dir 22A094_flye_output --threads 9

#OUTPUT: assembly.fasta

###################################
##Evaluacion de ensamblado: Quast##
###################################

conda activate quast
conda install bioconda::quast
quast -r GCF_006094395.1_ASM609439v1_genomic.fna 22A094_flye_output/assembly.fasta -o quast_output

#OUTPUT: icarus.html


