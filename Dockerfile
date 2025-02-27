# ======= Base Image =======
FROM ubuntu:22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# ======= Install Dependencies =======
FROM base AS dependencies

RUN apt-get update && apt-get install -y \
    # srsRAN 4G Dependencies
    cmake \
    ninja-build \
    build-essential \
    libfftw3-dev \
    libmbedtls-dev \
    libboost-program-options-dev \
    libconfig++-dev \
    libsctp-dev \
    # srsGUI Dependencies (for visualization)
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libqwt-qt5-dev \
    qtbase5-dev \
    # RF front-end driver support
    gnuradio \
    soapysdr-tools \
    uhd-host \
    libzmq3-dev \
    libczmq-dev \
    # Miscellaneous Support Libraries
    git \
    nano \
    sudo \
    python3 \
    python3-pip \
    iproute2 \
    net-tools \
    iputils-ping \
    xterm \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    && rm -rf /var/lib/apt/lists/*

# ======= Clone and Build srsRAN =======
FROM dependencies AS srsran-builder

RUN git clone https://github.com/srsran/srsRAN.git /opt/srsRAN && \
    cd /opt/srsRAN && \
    mkdir build && cd build && \
    cmake .. -G Ninja -DUSE_ZEROMQ=ON && \
    ninja && ninja install && \
    sudo /opt/srsRAN/build/srsran_install_configs.sh service

# ======= Final Runtime Image =======
FROM dependencies AS final

# Copy built srsRAN from builder stage
COPY --from=srsran-builder /opt/srsRAN /opt/srsRAN

# Copy generated config files
COPY --from=srsran-builder /etc/srsran /etc/srsran

# Set work directory
WORKDIR /workspace

# Copy additional files into the container
COPY README.md /workspace/
COPY srsRAN_4G_ZMQ_startup.sh /workspace/

# Make sure the script is executable
RUN chmod +x /workspace/srsRAN_4G_ZMQ_startup.sh

# Default command
CMD ["bash"]
