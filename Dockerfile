FROM elixir:1.12.2 as builder
ENV LANG=en_US.UTF-8
COPY server /app
COPY . /app
WORKDIR /app
RUN mix release

FROM debian:buster
COPY --from=builder /app/_build/dev/rel/affinity_tester /affinity_tester
WORKDIR /affinity_tester
CMD bin/affinity_tester start
