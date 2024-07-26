FROM quay.io/jupyter/pyspark-notebook:spark-3.5.1

ENV NB_USER datalab
ENV NB_UID 1000
ENV NB_GID 100
ENV HOME /home/datalab
ENV CONDA_DIR /opt/conda
ENV JUPYTER_ENABLE_LAB="yes"
WORKDIR /home/$NB_USER/work

USER root

# Install S3 Libraries
RUN wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.4.0/hadoop-aws-3.4.0.jar -O /usr/local/spark/jars/hadoop-aws-3.4.0.jar
RUN wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.765/aws-java-sdk-bundle-1.12.765.jar -O /usr/local/spark/jars/aws-java-sdk-bundle-1.12.765.jar

# Set up Datalab user (replacing default jovyan user)
RUN usermod -l $NB_USER -d /home/$NB_USER jovyan && \
    mkdir -p /home/$NB_USER/.jupyter && \
    mkdir -p $CONDA_DIR/pkgs/cache && \
    chown -R $NB_USER:$NB_GID /home/$NB_USER $CONDA_DIR/pkgs/cache && \
    fix-permissions $CONDA_DIR

USER $NB_UID

# Add Mamba for Speedy installs
RUN conda install mamba -y

# Install Panel from the pyviz channel
RUN mamba install -y conda-forge::panel
# Install Plotly from Ployly channel
RUN mamba install -y conda-forge::plotly
# Install nodejs
RUN mamba install -y conda-forge::nodejs
# Install dask labextension/ipywidgets/git integration/leaflet
RUN mamba install -y dask-labextension ipywidgets jupyterlab-git ipyleaflet widgetsnbextension

# Bake Dask/Dask-Kubernetes libraries into base Conda Environment
RUN mamba install -y -c conda-forge\
    ipyleaflet \
    dask \
    distributed \
    dask-kubernetes \
    dask-gateway \
    jupyter-server-proxy \
    bokeh \
    tornado \
    nbgitpuller \
    lz4 \ 
    voila \
    ipympl

# Add Jupyter Collaboration
RUN pip install jupyter-collaboration


RUN jupyter lab build --minimize=True --dev-build=False

USER root

RUN apt-get update && apt-get install -yq --no-install-recommends \
    vim && \
    rm -rf /var/lib/apt/lists/*

# Hotfix to remove temporary local files created during build causing problems and fix permissions on pkg cache
# Similiar to;
#  https://github.com/docker/for-linux/issues/433
#  https://stackoverflow.com/questions/52214178/file-permission-displayed-a-lot-question-marks-in-docker-container
RUN rm -rf /home/$NB_USER/.local/ /home/$NB_USER/.config/ && \
    mkdir -p $CONDA_DIR/pkgs/cache && \
    chown -R $NB_UID:$NB_GID /home/$NB_USER $CONDA_DIR/pkgs/cache

# Add env-control executable to control creation/deletion of Conda Environments
COPY env-control /usr/local/bin/env-control
# Make env-control executable
RUN chmod 755 /usr/local/bin/env-control

# Touch Assets Folder
RUN mkdir /assets

USER $NB_UID

