FROM python:3.10

ARG DEBIAN_FRONTEND=noninteractive 
ENV TZ=Europe/Berlin

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG REPO_URL=https://github.com/ASSERT-KTH/FLAMES
RUN git clone --depth 1 "$REPO_URL" .

RUN pip install --upgrade pip setuptools wheel && \
    pip install "numpy<2" && \
    pip install -r dataset/requirements.txt

RUN pip install pytest

RUN pip install -r feature_extraction/require-solidity-parser/requirements.txt

CMD ["/bin/bash"]
