FROM r-base:4.0.5
LABEL author="Anthony S. Castanza <acastanza@ucsd.edu> & Barbara A. Hill <bhill@broadinstitute.org>"

# for install log files - check here for log files when debugging
RUN mkdir /logs
RUN mkdir /logs/apt-get

# install system dependencies
RUN apt-get update --yes
RUN apt-get install build-essential=12.9 --yes
RUN apt-get install libcurl4-gnutls-dev=7.81.0-1 --yes
RUN apt-get install libxml2-dev=2.9.12+dfsg-5+b1 --yes
RUN apt-get install libssl-dev=1.1.1m-1 --yes
RUN apt-get install openssl=1.1.1m-1 --yes
# | tee /logs/apt-get_update.log

USER root

ENV R_HOME="/usr/lib/R"
RUN mkdir /logs/CRAN/

RUN mkdir /module
COPY module /module
COPY lib/*.tar.gz /module/
#make a nonroot user here

# RUN R -e "chooseCRANmirror(ind=1); install.packages(c('R.utils','getopt','optparse','dplyr','BiocManager'))"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/R.methodsS3_1.8.1.tar.gz', repo=NULL, type='source')"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/R.oo_1.24.0.tar.gz', repo=NULL, type='source')"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/R.utils_2.11.0.tar.gz', repo=NULL, type='source')"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/getopt_1.20.3.tar.gz', repo=NULL, type='source')"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/optparse_1.7.1.tar.gz', repo=NULL, type='source')"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/dplyr_1.0.7.tar.gz', repo=NULL, type='source')"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/BiocManager_1.30.16.tar.gz', repo=NULL, type='source')"
RUN R -e "BiocManager::install('rtracklayer', version = '3.12', ask = FALSE)"
RUN R -e "BiocManager::install('GenomicFeatures', version = '3.12', ask = FALSE)"
RUN R -e "BiocManager::install('Biostrings', version = '3.12', ask = FALSE)"
RUN R -e "BiocManager::install('BSgenome', version = '3.12', ask = FALSE)"
RUN R -e "BiocManager::install('eisaR', version = '3.12', ask = FALSE)"
RUN R -e "sessionInfo()"
RUN rm -rf /tmp/downloaded_packages/
# | tee /logs/apt-get_update.log

# build using this:
# docker build -t genepattern/prepvelocitytxome:beta .

CMD ["Rscript", "--version"]
