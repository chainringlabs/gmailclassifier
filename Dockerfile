# syntax=docker/dockerfile:1.29@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# Gmail Email Classifier - Dockerfile
# @spec OPS-IMAGE-001, OPS-IMAGE-002, OPS-IMAGE-003, OPS-IMAGE-004, OPS-IMAGE-005

# Base images come from chainringlabs/base-images: signature-verified copies of
# cgr.dev/chainguard/python, held back 3 days (`aged`). Both tags move together
# from the same daily record, so the builder's venv matches the runtime Python.
FROM ghcr.io/chainringlabs/base/python-dev:aged@sha256:3ca53097911a867be4f8190b8bc272d1465e9d95ef32ecc2cd70d841e2baeac3 AS builder

USER root

COPY --from=ghcr.io/astral-sh/uv:0.13@sha256:a3ea1357342c1a4bf9a0c53a3deb1b55379aefa037338d8113d5771efa01774f /uv /uvx /usr/local/bin/

WORKDIR /app

ENV UV_PROJECT_ENVIRONMENT=/app/.venv \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

RUN mkdir -p /app/data && chown -R nonroot:nonroot /app

FROM ghcr.io/chainringlabs/base/python:aged@sha256:3a89a9027f47e44e9f9da201493013249a02fc87fa7269bba80f621d7ade83f8

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
