FROM jupyter/pyspark-notebook:spark-3.1.2

ENV NB_USER datalab
ENV NB_UID 1000
ENV NB_GID 100
ENV HOME /home/datalab
ENV CONDA_DIR /opt/conda
ENV JUPYTER_ENABLE_LAB="yes"
ENV DASK_VERSION "2021.6.2"
WORKDIR /home/$NB_USER/work

USER root

# Install S3 Libraries
RUN wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.2.0/hadoop-aws-3.2.0.jar -O /usr/local/spark/jars/hadoop-aws-3.2.0.jar
RUN wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.563/aws-java-sdk-bundle-1.11.563.jar -O /usr/local/spark/jars/aws-java-sdk-bundle-1.11.563.jar

# Set up Datalab user (replacing default jovyan user)
RUN usermod -l $NB_USER -d /home/$NB_USER jovyan && \
    mkdir -p /home/$NB_USER/.jupyter && \
    mkdir -p $CONDA_DIR/pkgs/cache && \
    chown -R $NB_USER:$NB_GID /home/$NB_USER $CONDA_DIR/pkgs/cache && \
    fix-permissions $CONDA_DIR

USER $NB_UID

# Add Git integration
RUN pip install --no-cache-dir jupyterlab-git==0.30.1 && \
    jupyter labextension install @jupyterlab/git@0.30.1

# Add support for Widgets & Plots
RUN pip install --no-cache-dir ipywidgets==7.6.3 \
    ipyleaflet==0.14.0 && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    jupyter labextension install jupyter-leaflet && \
    jupyter labextension install jupyterlab-plotly && \
    jupyter lab build

# Add Dask Labextension
# JupyterLab 3.0 or greater - https://pypi.org/project/dask-labextension/
RUN pip install --no-cache-dir dask-labextension==5.0.2

# Bake Dask/Dask-Kubernetes libraries into base Conda Environment
RUN conda install -y \
    dask=$DASK_VERSION \
    distributed=$DASK_VERSION \
    dask-kubernetes=2021.3.1 \
    dask-gateway=0.9.0 \
    jupyter-server-proxy=3.0.2 \
    bokeh=2.3.2 \
    tornado=6.1 \
    nbgitpuller=0.10.1 \
    lz4=3.1.3

USER root

RUN apt-get update && apt-get install -yq --no-install-recommends \
    vim \
    && rm -rf /var/lib/apt/lists/*

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

USER $NB_UID
