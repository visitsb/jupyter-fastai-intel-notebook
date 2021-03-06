# Copyright (c) Amnico LLC
# SPDX-License-Identifier: BSD-3-Clause

ARG base_image="visitsb/jupyter-core-notebooks:latest"
FROM "$base_image"

# Fix DL4006
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Docker: Having issues installing apt-utils
# https://stackoverflow.com/a/56569081
ARG DEBIAN_FRONTEND=noninteractive

### install Intel(R) general purpose GPU (GPGPU) software packages
# https://dgpu-docs.intel.com/installation-guides/ubuntu/ubuntu-bionic.html
# https://www.networkinghowtos.com/howto/installing-lspci-on-centos/
USER root
WORKDIR /tmp

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends -o=Dpkg::Use-Pty=0 && \
    apt-get install -y gpg-agent software-properties-common wget pciutils && \
    wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | apt-key add - && \
    apt-add-repository 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu bionic main' && apt-get update -y && \
    apt-get install -y intel-opencl intel-level-zero-gpu level-zero intel-igc-opencl-devel level-zero-devel && \
    apt-get -y clean && apt-get -y autoremove && apt-get -y autoclean 

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
WORKDIR /tmp

### install Fastai (default is PyTorch with NVIDIA CUDA support; we have Intel® oneAPI PyTorch installed)
# Intel® oneAPI
# https://software.intel.com/content/www/us/en/develop/articles/installing-ai-kit-with-conda.html#gs.12pe6k
ARG ONEAPI_ENV=aikit

### download Fastai course books
# Setup work directory for downloading course book, sample training data
ARG FASTAI=".fastai"
ARG FASTBOOK="fastbook"

# Downloaded data, extract paths are as below-
# download_testdata.py --> $HOME/$FASTAI/archive
# extract.sh           --> $HOME/$FASTAI/data
COPY --chown=$NB_USER:$NB_GID download_testdata.py $HOME/$FASTAI/download_testdata.py
COPY --chown=$NB_USER:$NB_GID extract.sh $HOME/$FASTAI/extract.sh

# CONDA_PREFIX will be used to for pip install of Fastai under target ONEAPI_ENV
# https://github.com/fastai/fastai#installing
# "To install with pip, use: pip install fastai. If you install with pip, you should install PyTorch first"
# Fastai is built on top of PyTorch, and Intel oneAPI includes a CPU optimized PyTorch which we will use inside ONEAPI_ENV
ARG CONDA_PREFIX=$CONDA_DIR/envs/$ONEAPI_ENV

# Our base is already a Jupyter Notebook, so just pick any extra packages for Fastai within our Jupyter environment
# https://fastai1.fast.ai/install.html#jupyter-notebook-dependencies
#
# Also add kernelspec for ONEAPI_ENV
# https://www.pugetsystems.com/labs/hpc/Intel-oneAPI-AI-Analytics-Toolkit----Introduction-and-Install-with-conda-2068/
# 
# TODO: -c conda-forge intel-aikit-modin takes ridiculously long time for conda to resolve; skipping `intel-aikit-modin` from environment
RUN conda create -n $ONEAPI_ENV --quiet --yes -c intel intelpython3_full intel-aikit-tensorflow intel-aikit-pytorch && \
    conda install -n $ONEAPI_ENV --quiet --yes nb_conda nb_conda_kernels ipykernel pip && \
    $CONDA_PREFIX/bin/python -m pip install --quiet fastai jupyter_contrib_nbextensions ipywidgets && \
    $CONDA_PREFIX/bin/python -m ipykernel install --user --name $ONEAPI_ENV --display-name "Fastai (Intel® oneAPI)" && \
    conda update -n $ONEAPI_ENV --all --quiet --yes && \
    conda clean --all -f -y && \
    # $CONDA_PREFIX/bin/python $HOME/$FASTAI/download_testdata.py && \
    chmod u+x $HOME/$FASTAI/extract.sh && \
    # $HOME/$FASTAI/extract.sh && \
    git clone https://github.com/fastai/fastbook --depth 1 $FASTBOOK

# Copy kernel `logo` images to kernelspec
# https://jupyter-client.readthedocs.io/en/stable/kernels.html#kernel-specs
# `~/.local/share/jupyter/kernels` (Linux)
COPY --chown=$NB_USER:$NB_GID logo-32x32.png $HOME/.local/share/jupyter/kernels/$ONEAPI_ENV/logo-32x32.png
COPY --chown=$NB_USER:$NB_GID logo-64x64.png $HOME/.local/share/jupyter/kernels/$ONEAPI_ENV/logo-64x64.png

# INSTALLED PACKAGE OF SCIKIT-LEARN CAN BE ACCELERATED USING DAAL4PY.
# PLEASE SET 'USE_DAAL4PY_SKLEARN' ENVIRONMENT VARIABLE TO 'YES' TO ENABLE THE ACCELERATION.
ENV USE_DAAL4PY_SKLEARN=YES

# Fix permissions as root
USER root
WORKDIR /tmp

RUN fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
WORKDIR $HOME

# Make course book, data available to mount externally
VOLUME $HOME/$FASTBOOK
VOLUME $HOME/$FASTAI

# vim: nu:ai:ts=4:sw=4:fenc=utf-8
