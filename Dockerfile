FROM python:3.9 AS cactus_build

# build arguments
ARG DEBIAN_FRONTEND=noninteractive 
ARG RELEASE

# install build dependencies
RUN \
	apt-get update \
	&& apt-get install \
	--no-install-recommends -y \
		ca-certificates \
		curl \
		jq \
		lsb-release \
		sudo

# set workdir
WORKDIR /cactus-blockchain

# fetch source
RUN \
	if [ -z ${RELEASE+x} ]; then \
	RELEASE=$(curl -u "${SECRETUSER}:${SECRETPASS}" -sX GET "https://api.github.com/repos/Cactus-Network/cactus-blockchain/releases/latest" \
	| jq -r ".tag_name"); \
	fi \
	&& git clone --branch ${RELEASE} --recurse-submodules=mozilla-ca https://github.com/Cactus-Network/cactus-blockchain.git . \
	&& /bin/sh ./install.sh

FROM python:3.9-slim

# build arguments
ARG DEBIAN_FRONTEND=noninteractive

# environment variables
ENV \
        CACTUS_ROOT=/root/.cactus/mainnet \
        farmer_address= \
        farmer_port= \
        keys="generate" \
        log_level="INFO" \
        log_to_file="true" \
        outbound_peer_count="20" \
        peer_count="20" \
        plots_dir="/plots" \
        service="farmer" \
        testnet="false" \
        TZ="UTC" \
        upnp="true"

# legacy options
ENV \
	farmer="false" \
	harvester="false"

# set workdir
WORKDIR /cactus-blockchain

# install dependencies
RUN \
	apt-get update \
	&& apt-get install \
	--no-install-recommends -y \
		tzdata \
	\
# set timezone
	\
	&& ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime \
	&& echo "$TZ" > /etc/timezone \
	&& dpkg-reconfigure -f noninteractive tzdata \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# set additional runtime environment variables
ENV \
	PATH=/cactus-blockchain/venv/bin:$PATH

# copy build files
COPY --from=cactus_build /cactus-blockchain /cactus-blockchain

# copy local files
COPY docker-*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-*.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
