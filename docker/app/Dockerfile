ARG RUST_TAG=1.64.0
ARG APP_SNAKE=example
FROM rust:${RUST_TAG} as build

# cd "${PROJECT}"
# docker build --tag woc/work-on-capital-core:0.1.0-SNAPSHOT -f docker/app/Dockerfile .

RUN rustup component add rustfmt

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y cmake protobuf-compiler

WORKDIR /usr/src/${APP_SNAKE}
COPY monolith/ monolith/
COPY proto/ monolith/proto/
COPY *.rs ./
COPY Cargo.* ./
RUN bash -c 'touch monolith/src/proto_{admin,model,signup,${APP_SNAKE}}.rs monolith/src/dendrite_config.rs'

RUN cargo install --path monolith

FROM gcr.io/distroless/cc-debian10

COPY --from=build /usr/local/cargo/bin/${APP_SNAKE} /usr/local/bin/${APP_SNAKE}

CMD ["${APP_SNAKE}"]