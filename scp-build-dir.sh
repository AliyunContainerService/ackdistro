echo -n `git log -1 --pretty=format:%h` > /tmp/VERSION

EIP=39.101.77.160
scp -r build/* root@${EIP}:/root/cnstack/build/
scp -r /tmp/VERSION root@${EIP}:/root/cnstack/build