FROM r-base:4.0.5
MAINTAINER Anthony S. Castanza <acastanza@ucsd.edu>

USER root

RUN R -e "chooseCRANmirror(ind=1); install.packages(c('R.utils','getopt','optparse','dplyr','BiocManager'))"
RUN R -e "BiocManager::install('rtracklayer')"
RUN R -e "BiocManager::install('GenomicFeatures')"
RUN R -e "BiocManager::install('Biostrings')"
RUN R -e "BiocManager::install('BSgenome')"
RUN R -e "BiocManager::install('eisaR')"

RUN R -e "sessionInfo()"
RUN rm -rf /tmp/downloaded_packages/

RUN mkdir /module
COPY src /module

# build using this:
# docker build -t genepattern/prepvelocitytxome:1.0 .

CMD ["Rscript", "--version"]
