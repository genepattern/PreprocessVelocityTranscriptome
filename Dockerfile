FROM r-base:4.0.5
LABEL author="Anthony S. Castanza <acastanza@ucsd.edu>"

# install system dependencies
RUN apt-get update --yes
RUN apt-get install build-essential --yes
RUN apt-get install libcurl4-gnutls-dev --yes
RUN apt-get install libxml2-dev --yes
RUN apt-get install libssl-dev --yes
RUN apt-get install openssl --yes

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
