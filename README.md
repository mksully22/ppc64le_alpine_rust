# ppc64le_alpine_rust
# Usage:
# $ sudo docker run --name alpine_rustbuild  -it -v /rust-alpine-ppc64le:/mnt al
# $ sudo docker exec -it alpine_rustbuild  /bin/bash
# $ sudo docker ps
# # inside the docker container
# modify /etc/apk/repositories to point to edge
# apk update
# apk upgrade
# Copy the contents of this directory to build_rust.sh, patches to /root/test/.
# as root, execute /root/test/build_rust.sh
-