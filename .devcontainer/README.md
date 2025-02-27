## srsRAN 4G LG ZmQ Setup

The point of this .devcontainer is provide a quick way to deploy a 4G test setup with no hardware. 

To startup inside the container simply run 

```sudo ./srsRAN_4G_ZMQ_startup```

This command will spawn 3 terminal windows for the various components of the 4G system; EPC, eNodeB, UE. 

### Testing Commands
In the container terminal (separate from these 3 spawned terminals) Run the following commands to

#### Test Downlink

```ping 172.16.0.2```

#### Test Uplink
Utilize the ue1 network namespace that is created by the srsRAN_4G_ZMQ_start
```sudo ip netns exec ue1 ping```

# Dockerfile Overview

Base: ubuntu 22.04