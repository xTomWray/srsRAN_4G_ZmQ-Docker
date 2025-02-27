#!/bin/bash

echo "Starting srsRAN 4G with ZMQ..."

# Create network namespace
sudo ip netns add ue1
sudo ip netns list

if sudo ip netns list | grep -q "ue1"; then
    echo "✅ Network namespace ue1 created successfully"
else
    echo "❌ Error: ue1 namespace not found"
    exit 1
fi

# Start EPC in new terminal
xterm -hold -e "echo Starting EPC...; sudo /opt/srsRAN/build/srsepc/src/srsepc" &
sleep 5

# Start eNodeB in new terminal
xterm -hold -e "/opt/srsRAN/build/srsenb/src/srsenb --rf.device_name=zmq --rf.device_args='fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6'" &
sleep 5

# Start UE in new terminal
xterm -hold -e "sudo /opt/srsRAN/build/srsue/src/srsue --rf.device_name=zmq --rf.device_args='tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=23.04e6' --gw.netns=ue1" &
sleep 5

# Reminder for traffic testing
echo "✅ srsRAN 4G with ZMQ is now running!"
echo "Test downlink with: ping 172.16.0.2"
echo "Test uplink with: sudo ip netns exec ue1 ping 172.16.0.1"
echo "⚠️ Reminder: When finished, remove namespace with: sudo ip netns delete ue1"
