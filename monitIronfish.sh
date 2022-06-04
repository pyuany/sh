
#! /bin/bash
# monitIronfish.sh      
# read -p " 请输入节点名字（跟官方注册的一样）:" name
echo "你传入的节点名字是 $name"
install_ironfish(){
    while true 
    do
        geth_procnum=`docker exec -i node bash -c "ironfish config:show" | grep blockGraffiti|grep -v grep|wc -l`
        if [ $geth_procnum -eq 0 ]
        then
        echo "docker  start  ${name}..."
        docker  start node
        docker exec -it node bash -c "ironfish config:set blockGraffiti ${name}"
        docker exec -it node bash -c "ironfish config:set enableTelemetry true"
        fi
        sleep 30 #每30秒检查一轮
        echo "docker start ${name}..."
    done
}
install_ironfish
