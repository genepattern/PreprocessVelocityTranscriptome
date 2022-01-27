FROM r-base:4.0.5
LABEL author="Anthony S. Castanza <acastanza@ucsd.edu> & Barbara A. Hill <bhill@broadinstitute.org>"

# for install log files - check here for log files when debugging
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

RUN R -e “install.packages((‘/module/devtools_2.4.3.tar.gz’))”
RUN R -e “require(devtools)”
# RUN R -e "chooseCRANmirror(ind=1); install.packages(c('R.utils','getopt','optparse','dplyr','BiocManager'))"
RUN R -e “install_version(‘R.utils’, version = “2.11.0”, dependencies= T)”
RUN R -e “install_version(‘getopt’, version = “1.20.3”, dependencies= T)”
RUN R -e “install_version(‘optparse’, version = “1.7.1”, dependencies= T)”
RUN R -e “install_version(‘dplyr’, version = “1.0.7”, dependencies= T)”
RUN R -e “install_version(‘BiocManager’, version = “1.30.16”, dependencies= T)”
RUN R -e "BiocManager::install('rtracklayer', version = "3.12", ask = FALSE)"
RUN R -e "BiocManager::install('GenomicFeatures', version = "3.12", ask = FALSE)"
RUN R -e "BiocManager::install('Biostrings', version = "3.12", ask = FALSE)"
RUN R -e "BiocManager::install('BSgenome', version = "3.12", ask = FALSE)"
RUN R -e "BiocManager::install('eisaR', version = "3.12", ask = FALSE)"
RUN R -e "sessionInfo()"
RUN rm -rf /tmp/downloaded_packages/
# | tee /logs/apt-get_update.log

# build using this:
# docker build -t genepattern/prepvelocitytxome:beta .

CMD ["Rscript", "--version"]
