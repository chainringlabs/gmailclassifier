# syntax=docker/dockerfile:1.29@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Gmail Email Classifier - Dockerfile
# @spec OPS-IMAGE-001, OPS-IMAGE-002, OPS-IMAGE-003, OPS-IMAGE-004, OPS-IMAGE-005

FROM cgr.dev/chainguard/python:latest-dev@sha256:c047e6d1e47b09144a771bfde6595a00c49dc8571caa7dd62df88634e84304ae AS builder

USER root

COPY --from=ghcr.io/astral-sh/uv:0.11@sha256:77280f2f771df71f90786c314fe1bbc1e023feac652969bbf139c280babf2eb7 /uv /uvx /usr/local/bin/

WORKDIR /app

ENV UV_PROJECT_ENVIRONMENT=/app/.venv \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

RUN mkdir -p /app/data && chown -R nonroot:nonroot /app

FROM cgr.dev/chainguard/python:latest@sha256:f6e5c2e056393d48fa8afa1ea58a1394db4cd5de1a8f0f48105c8e88fcd4f9d3

WORKDIR /app

COPY --from=builder --chown=nonroot:nonroot /app/.venv /app/.venv
COPY --from=builder --chown=nonroot:nonroot /app/data /app/data
COPY --chown=nonroot:nonroot *.py ./

ENV PATH="/app/.venv/bin:$PATH" \
    GMAIL_CREDENTIALS_PATH=/app/credentials.json \
    GMAIL_TOKEN_PATH=/app/token.json \
    GMAIL_HEADLESS_MODE=true \
    CLASSIFIER_CONFIG_PATH=/app/classifier_config.json \
    STATE_FILE=/app/data/.email_state.json

ENTRYPOINT []
CMD ["python", "main.py"]
