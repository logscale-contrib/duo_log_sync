FROM python:3.8.16-bullseye as base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1
RUN mkdir /app
WORKDIR /app

FROM base as builder

COPY MANIFEST.in LICENSE requirements.txt setup.cfg setup.py README.md /work/
COPY tests /work/tests
COPY duologsync /work/duologsync
WORKDIR /app
RUN python3.8 -m venv /app/.venv ;\
    . /app/.venv/bin/activate ;\
    pip install -r /work/requirements.txt ;\
    pip install /work


FROM base as final

COPY --from=builder /app/.venv /app/.venv
COPY entrypoint.sh ./
ENTRYPOINT ["./entrypoint.sh"]