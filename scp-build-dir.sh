echo -n `git log -1 --pretty=format:%h` > /tmp/VERSION

EIP=47.103.121.223
scp -r build/* root@${EIP}:/root/cnstack/build/
scp -r /tmp/VERSION root@${EIP}:/root/cnstack/build