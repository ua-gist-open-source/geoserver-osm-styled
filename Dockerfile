FROM ubuntu

RUN apt update && apt install -y wget

RUN cd / && wget https://github.com/omniscale/imposm3/releases/download/v0.11.1/imposm-0.11.1-linux-x86-64.tar.gz && tar xvf imposm-0.11.1-linux-x86-64.tar.gz && ln -s /imposm-0.11.1-linux-x86-64/imposm /usr/local/bin/imposm && rm /imposm-0.11.1-linux-x86-64.tar.gz

