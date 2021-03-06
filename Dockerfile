FROM golang:1.13.1 as bd
RUN adduser --disabled-login --gecos "" appuser
WORKDIR /github.com/layer5io/meshery-istio
ADD . .
RUN GOPROXY=direct GOSUMDB=off go build -ldflags="-w -s" -a -o /meshery-istio .
RUN find . -name "*.go" -type f -delete; mv istio /
RUN wget -O /istio.tar.gz https://github.com/istio/istio/releases/download/1.5.1/istio-1.5.1-linux.tar.gz

FROM alpine
RUN apk --update add ca-certificates curl
RUN mkdir /lib64 && \
	ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
	mkdir -p /root/.kube && \
	mkdir -p /tmp/istio
COPY --from=bd /meshery-istio /app/
COPY --from=bd /istio /app/istio
COPY --from=bd /istio.tar.gz /app/
COPY --from=bd //github.com/layer5io/meshery-istio/scripts /app/scripts/.
COPY --from=bd /etc/passwd /etc/passwd
ENV ISTIO_VERSION=1.7.3
# USER appuser
WORKDIR /app
CMD ./meshery-istio
