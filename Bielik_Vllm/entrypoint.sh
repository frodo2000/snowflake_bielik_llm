#!/bin/bash

start_service() {
    local log_file_basename=$1

    # Generate the current date/hour/minute format
    local datetime_prefix=$(date +"%Y%m%d-%H%M")

    # Modify log_file to include the datetime prefix and models directory
    local log_file="/models/logs/${datetime_prefix}_${log_file_basename}"

    mkdir -p /models/logs
    touch $log_file

    echo "Starting vLLM server..."
    python3 -m vllm.entrypoints.openai.api_server --model $MODEL --max-model-len $MODEL_MAX_LEN --tensor-parallel-size $TENSOR_PARALLEL --gpu-memory-utilization $GPU_MEM_UTIL --download-dir /models/ --trust-remote-code > $log_file 2>&1 &

    # Start tailing the logs and send the process to background
    tail -F $log_file &

    echo "Waiting for vLLM server to be ready..."
    while true
    do
      if grep -q "Uvicorn running" $log_file || grep -q "100%" $log_file; then
        break
      fi
      sleep 1
    done

    # Stop tailing the logs after the service is ready
    pkill -P $$ tail

    echo "vLLM server is ready."
}

start_service vllm.log

# wait indefinitely
tail -f /dev/null