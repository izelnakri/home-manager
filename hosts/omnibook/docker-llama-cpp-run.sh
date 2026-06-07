# NOTE: This worked on llama-cpp github repo, make it run with a local ollama dist, run llama-cpp as server
docker build -t llama-cpp-sycl --build-arg="GGML_SYCL_F16=ON" --target light -f .devops/intel.Dockerfile .
sudo docker run -it \
    --device /dev/dri/renderD128:/dev/dri/renderD128 \
    --device /dev/dri/card0:/dev/dri/card0 \
    --device /dev/accel/accel0 \
    -v "/home/izelnakri/.ollama:/.ollama" \
    --name llama-cpp-sycl \
    llama-cpp-sycl \
    -m "/.ollama/models/blobs/sha256-6340dc3229b0d08ea9cc49b75d4098702983e17b4c096d57afbbf2ffc813f2be" \
    -cnv -ngl 20000 -e --color

# TODO:
# - make it work with ollama
# - optimize model
# - optimize flags
# - optimize Dockerfile
#
#
# # NOTE: This works! Check nvprof, oprofile | Check ZES_ENABLE_SYSMAN=1
# # Make it runnable on NPU
# docker build -t llama-cpp-sycl --build-arg="GGML_SYCL_F16=ON" --target light -f .devops/intel.Dockerfile .
#
#
# sudo docker remove llama-cpp-syscl && \
# sudo docker run -it \
#     --device /dev/dri/renderD128:/dev/dri/renderD128 \
#     --device /dev/dri/card0:/dev/dri/card0 \
#     --device /dev/accel/accel0 \
#     -v "/home/izelnakri/.ollama:/.ollama" \
#     --name llama-cpp-sycl \
#     llama-cpp-sycl \
#     -m "/.ollama/models/blobs/sha256-6340dc3229b0d08ea9cc49b75d4098702983e17b4c096d57afbbf2ffc813f2be" \
#     -cnv -ngl 20000 -p "" -e --color
#     # maybe change -ngl and add -n, -p is prompt, -cnv is optional
#
# # Deepseek:8b = -m "/.ollama/models/blobs/sha256-6340dc3229b0d08ea9cc49b75d4098702983e17b4c096d57afbbf2ffc813f2be" \
# # Couldnt run these yet, maybe due to -ngl or the ZES_ENABLE_SYSMAN or smt:
# # Deepseek:14b = -m "/.ollama/models/blobs/sha256-6e9f90f02bb3b39b59e81916e8cfce9deb45aeaeb9a54a5be4414486b907dc1e" \
# # Deepseek:32b = -m "/.ollama/models/blobs/sha256-6150cb382311b69f09cc0f9a1b69fc029cbd742b66bb8ec531aa5ecf5c613e93" \
#
# # TODO:
# # Toggle perf metrics
# # Monitor GPU util, move it to tmux bottom
# # Make it runnable on NPU
# # Make it runnable as a server than one-shot responses
# # Make it runnable on ollama
# # Make it runnable with optimized model
# # Make it runnable on NixOS
