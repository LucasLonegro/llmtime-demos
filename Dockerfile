# -----------------------------------------------------------------------------
# Stage: deps — install Python packages only. Cached until requirements.txt
# or TORCH_INDEX_URL changes; not invalidated by application code edits.
# -----------------------------------------------------------------------------
FROM python:3.11 AS deps

# Default to cu132 for PyTorch (supports Blackwell sm_120)
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/nightly/cu132

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/deps

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN python -m pip install --upgrade pip setuptools wheel && \
    \
    python -m pip install --pre torch torchvision torchaudio \
        --index-url ${TORCH_INDEX_URL} && \
    \
    python -m pip install \
        "numpy==1.26.4" \
        "pandas==1.5.3" && \
    \
    python -m pip install --no-deps -r requirements.txt && \
    \
    python -m pip install \
        "jax[cuda12]" \
        matplotlib \
        tqdm \
        transformers \
        datasets \
        accelerate \
        gpytorch \
        "darts>=0.24.0,<0.35.0" \
        multiprocess \
        SentencePiece \
        gdown \
        openai==0.28.1 \
        tiktoken \
        mistralai==0.4.2 \
        "notebook>=6.5,<7"

# -----------------------------------------------------------------------------
# Stage: runtime — thin image + vendored site-packages; COPY . only here.
# -----------------------------------------------------------------------------
FROM python:3.11 AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /workspace

# Runtime libs for PyTorch / numpy / JAX wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=deps /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin

COPY . /workspace

CMD ["python", "demo.py"]