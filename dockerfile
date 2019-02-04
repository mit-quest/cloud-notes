FROM ubuntu

# Needed to secure the container.
ARG USER_ID

ENV WORKSPACE workspace
ENV USERNAME jupyter-cloud

ENV DOCKER_LOCALE en_US.UTF-8 

RUN apt-get -qq update
RUN apt-get -qq install -y --no-install-recommends \ 
    locales

RUN locale-gen $DOCKER_LOCALE
ENV LANG $DOCKER_LOCALE

RUN apt-get -qq install -y --no-install-recommends \
    python3     \
    python3-dev \
    python3-pip \
    python3-setuptools

RUN python3 -m pip -q install --upgrade \
    pip \
    setuptools \
    jupyter

RUN mkdir -p /$WORKSPACE \
    && useradd \
        --create-home \
        --shell /bin/bash \
        --non-unique   \
        --uid $USER_ID \
        --system \
        $USERNAME \
    && chown $USERNAME /$WORKSPACE

USER $USERNAME

WORKDIR /$WORKSPACE
COPY $WORKSPACE/* ./

RUN python3 -m pip install -r ./requirements.txt

# Running jupyter inside of a container requires --ip 0.0.0.0 for host connection to notebook server
# Since running in a container, ensure no browser is loaded, --no-browser
#
CMD ["python3", "-m", "jupyter", "notebook", "--ip", "0.0.0.0", "--no-browser"]
