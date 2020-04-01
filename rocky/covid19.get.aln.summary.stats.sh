#!/bin/bash
#Extract samtools stats from each file in parallel
outputdir="/media/dstore/renzo/samtools_stats"
rm -f $outputdir/samtools.stats.commands.txt
for i in `find /media/dstore/covid19/sravsref.minimap2 -name "*.bam" | sort |uniq`
do
echo "samtools stats $i | grep ^SN | cut -f 3 > $outputdir/`basename $i .bam`.stats.tmp" >> $outputdir/samtools.stats.commands.txt
done

commandsfile=$outputdir/samtools.stats.commands.txt
joblog=$outputdir/samtools.stats.commands.log
cores=16
parallel --joblog $joblog -j $cores <$commandsfile

#Add row names/descriptions
outputdir=/media/dstore/renzo/sumstats_covid19
inputdir=/media/dstore/renzo/samtools_stats
samtools stats /media/dstore/covid19/sravsref.minimap2/SRR11433893.minimap2.aln.bam | grep ^SN | cut -f2 > $outputdir/samtools.stats.rownames.txt
sed -i '1s/^/sampleID:\n/' $outputdir/samtools.stats.rownames.txt

#Combine into a table
outputdir=/media/dstore/renzo/sumstats_covid19
rm -f $outputdir/tmp.txt
rm -f $outputdir/summary.stats.sravsref.minimap2.txt
cat $outputdir/samtools.stats.rownames.txt > $outputdir/summary.stats.sravsref.minimap2.txt
for i in `find /media/dstore/renzo/samtools_stats -name "*.stats.tmp" | grep 'SRR'| sort |uniq`
do
sampleID=`basename $i | cut -d '.' -f1`
cat $i | sed "1s/^/$sampleID\n/" > $outputdir/tmp.txt
paste $outputdir/summary.stats.sravsref.minimap2.txt $outputdir/tmp.txt >> $outputdir/tmp2.txt
mv $outputdir/tmp2.txt $outputdir/summary.stats.sravsref.minimap2.txt
done


##########################################
#Extract other stats from bam file
outputdir="/media/dstore/renzo/samtools_stats"
rm -f $outputdir/stats.commands2.txt
for i in `find /media/dstore/covid19/sravsref.minimap2 -name "*.bam" | grep 'SRR' | sort |uniq`
do
map=`samtools idxstats $i | grep 'MN908947.3' | cut -f3`
mapelse=`samtools idxstats $i | grep -v 'MN908947.3' | cut -f3 | awk '{s+=$1} END {print s}'`
unmap=`samtools idxstats $i | awk '$1=="*"' | cut -f4 | awk '{s+=$1} END {print s}'`
unmapwocoords=`samtools idxstats $i | awk '$1=="*"' | cut -f4`
echo "samtools view -h -q 20 $i | wc -l > $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 40 $i | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 60 $i | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 80 $i | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp; echo "$map" >> $outputdir/`basename $i .bam`.2stats.tmp; echo "$mapelse" >> $outputdir/`basename $i .bam`.2stats.tmp; echo "$unmap" >> $outputdir/`basename $i .bam`.2stats.tmp; echo "$unmapwocoords" >> $outputdir/`basename $i .bam`.2stats.tmp; awk -v var1="$map" -v var2="$mapelse" 'BEGIN { print  ( var1 / (var1 + var2) ) }' >> $outputdir/`basename $i .bam`.2stats.tmp; awk -v var1="$map" -v var2="$mapelse" -v var3="$unmap" 'BEGIN { print  ( var1 / (var1 + var2 + var3) ) }' >> $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 20 $i | grep 'MN908947.3' | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 40 $i | grep 'MN908947.3' | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 60 $i | grep 'MN908947.3' | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp; samtools view -h -q 80 $i | grep 'MN908947.3' | wc -l >> $outputdir/`basename $i .bam`.2stats.tmp" >> $outputdir/stats.commands2.txt
done

commandsfile=$outputdir/stats.commands2.txt
joblog=$outputdir/stats.commands2.log
cores=16
parallel --joblog $joblog -j $cores <$commandsfile

#Add row names/descriptions
outputdir=/media/dstore/renzo/sumstats_covid19
inputdir=/media/dstore/renzo/samtools_stats
echo "No of reads at MAPQ 20:
No of reads at MAPQ 40:
No of reads at MAPQ 60:
No of reads at MAPQ 80:
No of mapped-read segments to COVID-19 (MN908947.3):
No of mapped-read segments that map elsewhere other than COVID-19:
No of unmapped-read segments:
No of unmapped-read segments without coordinates:
Percentage of mapped COVID-19 reads vs mapped reads (COVID-19 mapped/COVID-19 mapped + map elsewhere):
Percentage of mapped COVID-19 reads vs all reads  (COVID-19 mapped/ COVID-19 mapped + map elsewhere + unmapped):
No of reads that map to COVID-19 at MAPQ 20:
No of reads that map to COVID-19 at MAPQ 40:
No of reads that map to COVID-19 at MAPQ 60:
No of reads that map to COVID-19 at MAPQ 80:" > $outputdir/stats2.rownames.txt

#Combine into a table
outputdir=/media/dstore/renzo/sumstats_covid19
rm -f $outputdir/tmp.txt
rm -f $outputdir/2stats.sravsref.minimap2.txt
cat $outputdir/stats2.rownames.txt > $outputdir/2stats.sravsref.minimap2.txt
for i in `find /media/dstore/renzo/samtools_stats -name "*.2stats.tmp" | grep 'SRR'| sort |uniq`
do
cat $i > $outputdir/tmp.txt
paste $outputdir/2stats.sravsref.minimap2.txt $outputdir/tmp.txt >> $outputdir/tmp2.txt
mv $outputdir/tmp2.txt $outputdir/2stats.sravsref.minimap2.txt
done

#######################################
#Concatenate both metadata files
cat $outputdir/summary.stats.sravsref.minimap2.txt $outputdir/2stats.sravsref.minimap2.txt > $outputdir/covid19.summary.stats.sravsref.minimap2.txt