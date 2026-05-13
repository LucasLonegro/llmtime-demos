# -----------------------------------------------------------------------------
# Stage: deps — install Python packages only. Cached until requirements.txt
# or TORCH_INDEX_URL changes; not invalidated by application code edits.
# -----------------------------------------------------------------------------
FROM python:3.9-slim AS deps

ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN python -m pip install --upgrade pip && \
    python -m pip install "numpy>=1.23.5,<2" && \
    python -m pip install torch --index-url ${TORCH_INDEX_URL} && \
    python -m pip install -r requirements.txt && \
    python -m pip install "numpy>=1.23.5,<2" "pandas>=1.5.0,<2.0.0" --force-reinstall --no-cache-dir

# -----------------------------------------------------------------------------
# Stage: runtime — thin image + vendored site-packages; COPY . only here.
# -----------------------------------------------------------------------------
FROM python:3.9-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /workspace

# Runtime libs for PyTorch / numpy wheels (no compiler needed here).
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=deps /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin

COPY . /workspace

CMD ["python", "demo.py"]
