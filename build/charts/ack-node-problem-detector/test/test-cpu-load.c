//loadThreshold:负载阈值 loadThreshold=12*2=24
//$(echo "${loadThreshold} < $(uptime | awk -F'[ ,]' '{print $16}')" | bc)  判断大小：前面小，true，1；前面大，false，0。
//uptime | awk -F'[ ,]' '{print $16}'  提取的数据是系统过去一分钟的平均负载，平均负载等于逻辑CPU个数


//获取cpu核数
cat /proc/cpuinfo |grep "physical id" | wc -l
//开始 N等于cpu核数
for i in `seq 1 N`; do dd if=/dev/zero of=/dev/null & done
//结束
pkill -9 dd