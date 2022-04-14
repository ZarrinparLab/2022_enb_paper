
MANIFEST=../MANIFEST.tsv
## primary artifacts
qiime tools import \
    --type 'SampleData[PairedEndSequencesWithQuality]' \
    --input-format PairedEndFastqManifestPhred33V2 \
    --input-path $MANIFEST \
    --output-path 00.raw_paired_reads.qza

## dada2 with these options gave _terrible_ results
# qiime dada2 denoise-paired \
#    --i-demultiplexed-seqs 00.raw_paired_reads.qza \
#    --p-trunc-len-f 250 \
#    --p-trunc-len-r 200 \
#    --p-n-threads 12 \
#    --o-representative-sequences 01.dada2.asv.seqs.qza \
#    --o-table 01.dada2.asv.counts.qza \
#    --o-denoising-stats 01.dada2.stats.qza

qiime deblur denoise-16S \
    --i-demultiplexed-seqs 00.raw_paired_reads.qza \
    --p-trim-length 150 \
    --o-table 01.deblur.asv.counts.qza 
    --o-representative-sequences 01.deblur.asv.seqs.qza \
    --o-stats 01.deblur.asv.stats.qza \
    --p-sample-stats \
    --p-jobs-to-start 16

qiime feature-table filter-features \
    --p-min-samples 2 \
    --i-table 01.deblur.asv.counts.qza \
    --o-filtered-table 02.freq_filtered.asv.counts.qza
    
qiime feature-table filter-samples \
    --p-min-features 20 \
    --i-table  02.freq_filtered.asv.counts.qza \
    --o-filtered-table 03.sample_filtered.asv.counts.qza
    
qiime feature-table filter-seqs \
    --i-data 01.deblur.asv.seqs.qza \
    --i-table 03.sample_filtered.asv.counts.qza \
    --o-filtered-data 03.sample_filtered.asv.seqs.qza

qiime feature-classifier classify-sklearn \
    --i-reads  03.sample_filtered.asv.seqs.qza\
    --i-classifier /mnt/zarrinpar/Pynchon/Databases/qiime2/silva-138-99-nb-classifier.qiime2-2020.11.qza \
    --p-n-jobs 16 \
    --o-classification 04.sklearn.silva.asv.taxonomy.qza
    
qiime taxa filter-table \
    --p-exclude unassigned,mitochondria,chloroplast,eukaryota  \
    --i-table 03.sample_filtered.asv.counts.qza \
    --i-taxonomy 04.sklearn.silva.asv.taxonomy.qza \
    --o-filtered-table 04.taxonomy_filtered.asv.counts.qza

qiime taxa filter-seqs \
    --p-exclude unassigned,mitochondria,chloroplast,eukaryota \
    --i-sequences 03.sample_filtered.asv.seqs.qza \
    --i-taxonomy 04.sklearn.silva.asv.taxonomy.qza \
    --o-filtered-sequences 04.taxonomy_filtered.asv.seqs.qza

qiime taxa barplot \
    --i-table 04.taxonomy_filtered.asv.counts.qza \
    --i-taxonomy 04.sklearn.silva.asv.taxonomy.qza \
    --m-metadata-file $MANIFEST \
    --o-visualization 04.taxonomy_filtered.asv.taxa_barplot

qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences 04.taxonomy_filtered.asv.seqs.qza \
    --o-alignment 05.mafft_fasttree.aligned_seqs.qza \
    --o-masked-alignment 05.mafft_fasttree.masked_aligned_seqs.qza \
    --o-tree 05.mafft_fasttree.unrooted_tree.qza \
    --o-rooted-tree 05.mafft_fasttree.rooted_tree.qza
    
## and then basic diversity analyses

qiime diversity core-metrics-phylogenetic \
    --i-table 04.taxonomy_filtered.asv.counts.qza \
    --i-phylogeny 05.mafft_fasttree.rooted_tree.qza \
    --m-metadata-file $MANIFEST \
    --p-sampling-depth 10000 \
    --output-dir 06.core_metrics_phlyogenetic \
    --p-n-jobs-or-threads auto