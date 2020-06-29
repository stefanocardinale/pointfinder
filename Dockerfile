#- This creates a layer from the bifrost-base docker image------------------------------------------
FROM ssidk/bifrost-base:2.0.5

#- These are variables that are used at build-time--------------------------------------------------
ARG version="v2.2.5"
ARG last_updated="21/06/2021"
ARG name="pointfinder"
ARG full_name="${name}"

#- label instructions are key-value pairs that add metadata to the image----------------------------
LABEL \
    name=${name} \
    description="Docker environment for ${full_name}" \
    version=${version} \
    resource_version=${last_updated} \
    maintainer="stca@ssi.dk;"

#- Tools to install:start---------------------------------------------------------------------------
RUN \
    conda install -yq -c conda-forge -c bioconda -c default blast;
#- Tools to install:end ----------------------------------------------------------------------------

#- Additional resources (files/DBs): start ---------------------------------------------------------
RUN cd /bifrost_resources && \
    wget -q https://raw.githubusercontent.com/ssi-dk/bifrost/master/setup/adapters.fasta && \
    chmod +r adapters.fasta
#- Additional resources (files/DBs): end -----------------------------------------------------------

#- Source code:start -------------------------------------------------------------------------------
RUN cd /bifrost && \
    git clone --branch ${version} https://github.com/stefanocardinale/${full_name}.git ${name};
#- Source code:end ---------------------------------------------------------------------------------

#- Set up entry point:start ------------------------------------------------------------------------
ENV PATH /bifrost/${name}/:$PATH
ENTRYPOINT ["launcher.py"]
CMD ["launcher.py", "--help"]
#- Set up entry point:end ------