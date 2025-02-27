# Base Image
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
    /opt/srsRAN/build/srsran_install_configs.sh user

# ======= Final Runtime Image =======
FROM dependencies AS final

# Copy built srsRAN from builder stage
COPY --from=srsran-builder /opt/srsRAN /opt/srsRAN

# Set work directory
WORKDIR /workspace
COPY README.md /workspace/
# ======= Create the srsRAN_4G_ZMQ_startup script =======
CMD service dbus start && exec bash
RUN mkdir -p /workspace && \
    echo '#!/bin/bash' > /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'echo "Starting srsRAN 4G with ZMQ..."' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '# Create network namespace' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'sudo ip netns add ue1' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'sudo ip netns list' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'if sudo ip netns list | grep -q "ue1"; then' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '    echo "✅ Network namespace ue1 created successfully"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'else' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '    echo "❌ Error: ue1 namespace not found"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '    exit 1' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'fi' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '# Start EPC in new terminal' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'xterm -hold -e "echo Starting EPC...; sudo /opt/srsRAN/build/srsepc/src/srsepc"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'sleep 5' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '# Start eNodeB in new terminal' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'xterm -hold -e "echo Starting eNodeB...; /opt/srsRAN/build/srsenb/src/srsenb --rf.device_name=zmq --rf.device_args='\''fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6'\''"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'sleep 5' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '# Start UE in new terminal' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'xterm -hold -e "echo Starting UE...; sudo /opt/srsRAN/build/srsue/src/srsue --rf.device_name=zmq --rf.device_args='\''tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=23.04e6'\'' --gw.netns=ue1"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'sleep 5' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo '# Reminder for traffic testing' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'echo "✅ srsRAN 4G with ZMQ is now running!"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'echo "Test downlink with: ping 172.16.0.2"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'echo "Test uplink with: sudo ip netns exec ue1 ping 172.16.0.1"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    echo 'echo "⚠️ Reminder: When finished, remove namespace with: sudo ip netns delete ue1"' >> /workspace/srsRAN_4G_ZMQ_startup && \
    chmod +x /workspace/srsRAN_4G_ZMQ_startup


