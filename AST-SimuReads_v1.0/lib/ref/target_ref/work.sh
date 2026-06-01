wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/018/035/GCF_000240185.1_ASM24018v2/GCF_000240185.1_ASM24018v2_genomic.fna.gz # Klebsiella pneumoniae
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/018/035/GCF_002116925.1_ASM211692v1/GCF_002116925.1_ASM211692v1_genomic.fna.gz  #Acinetobacter baumannii
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/008/865/GCF_000008865.2_ASM886v2/GCF_000008865.2_ASM886v2_genomic.fna.gz #Escherichia coli
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_genomic.fna.gz #Pseudomonas aeruginosa
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/113/365/GCF_001113365.1_6823_7_22/GCF_001113365.1_6823_7_22_genomic.fna.gz #Streptococcus pneumoniae

cat *_genomic.fna > ref.fa

