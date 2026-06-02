FROM python:3.10

ARG DEBIAN_FRONTEND=noninteractive 
ENV TZ=Europe/Berlin

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG REPO_URL=https://github.com/ASSERT-KTH/FLAMES
RUN git clone --depth 1 "$REPO_URL" .

# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir "numpy<2" \
    && pip install --no-cache-dir -r dataset/requirements.txt \
    && pip install --no-cache-dir pytest \
    && pip install --no-cache-dir -r feature_extraction/require-solidity-parser/requirements.txt

CMD ["/bin/bash"]
