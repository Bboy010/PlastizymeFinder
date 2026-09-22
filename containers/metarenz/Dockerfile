# PlastizymeFinder — MeTarEnz runtime image
#
# The upstream image published by the MeTarEnz authors (mforooz/metarenz) does
# not ship procps, so `ps` is missing. Nextflow needs `ps` to collect task
# metrics whenever trace/report/timeline are enabled, which PlastizymeFinder
# does by default — without it every MeTarEnz task fails.
#
# This image adds procps and nothing else, so the scientific behaviour of
# MeTarEnz is untouched. The base is Debian 10 (buster), which is end-of-life,
# so its packages are pulled from archive.debian.org.
#
# Build and publish:
#   docker build -t <registry>/plastizymefinder-metarenz:1.0 containers/metarenz
#   docker push  <registry>/plastizymefinder-metarenz:1.0
#
# Upstream tool : https://github.com/mehdiforoozandeh/MeTarEnz
# Upstream image: https://hub.docker.com/r/mforooz/metarenz
# Citation      : Foroozandeh Shahraki et al. (2024) Nat. Prod. Bioprospect.
#                 https://doi.org/10.1007/s13659-023-00426-8

FROM mforooz/metarenz:latest

LABEL org.opencontainers.image.title="plastizymefinder-metarenz" \
      org.opencontainers.image.description="MeTarEnz with procps added for Nextflow task metrics" \
      org.opencontainers.image.source="https://github.com/Bboy010/PlastizymeFinder" \
      org.opencontainers.image.base.name="docker.io/mforooz/metarenz:latest"

RUN printf '%s\n' \
        'deb http://archive.debian.org/debian buster main' \
        'deb http://archive.debian.org/debian-security buster/updates main' \
        > /etc/apt/sources.list \
 && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid-until \
 && apt-get update \
 && apt-get install -y --no-install-recommends procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /home/MeTarEnz
