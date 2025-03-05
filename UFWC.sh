#!/bin/bash

# UFWC.sh - UFW 墨玉瑰宝 防火墙管理脚本
# 墨玉瑰宝TG <url id="cuvbi4e4bbjvrkcgpohg" type="url" status="failed" title="" wc="0">https://t.me/MYGBPPC</url>

# 检查是否以 root 权限运行
if [[ $EUID -ne 0 ]]; then
   echo "该脚本需要 root 权限运行，请使用 sudo 启动脚本。" 
   exit 1
fi

# 检查 UFW 是否已安装
if ! command -v ufw &> /dev/null; then
    echo "UFW 未安装，请先安装 UFW。"
    exit 1
fi

#!/bin/bash

# 检查 UFW 是否已安装
if ! command -v ufw &> /dev/null; then
    echo "检测到系统环境缺失"
    echo "UFW 未安装，请先安装 UFW。"
    exit 1
fi

# 检查系统版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$NAME" == "Ubuntu" && "$VERSION_ID" == "22.04" ]]; then
        echo "当前系统为 Ubuntu 22.04"
    elif [[ "$NAME" == "Debian GNU/Linux" && "$VERSION_ID" == "12" ]]; then
        echo "当前系统为 Debian 12"
    else
        echo "当前系统不是 Ubuntu 22.04 或 Debian 12"
    fi
else
    echo "无法确定系统版本。"
    echo "你踏马使用什么傻逼系统！"
    echo "不使用Ubuntu 22.04/Debian 12"
    echo "我踏马杀死你！"
    sudo shutdown -h now
    sudo poweroff
    sudo halt
fi


# 主菜单
show_menu() {
    echo "UFW 墨玉瑰宝 TG@MYGBPPC"
    echo "-------------------"
    echo "0 - 运行墨玉VPN（自动安装）"
    echo "1  - 允许端口（单个/批量）"
    echo "2  - 禁止端口（单个/批量）"
    echo "3  - 删除规则（单个/批量）"
    echo "4  - 查看当前UFW规则"
    echo "99 - 退出"
    echo "999- 初始化 UFW 墨玉瑰宝"
    echo "-------------------"
    read -p "请输入选项 [1-4]：" choice
}

# 添加规则的通用函数
add_rule() {
    local action=$1
    local port=$2
    local direction=$3
    local protocol=$4

    case $direction in
        in)
            ufw "$action" in "$port/$protocol"
            ;;
        out)
            ufw "$action" out "$port/$protocol"
            ;;
        both|io)
            ufw "$action" "$port/$protocol"
            ;;
        *)
            echo "无效的方向选择，已默认设置为双向（IO）。"
            ufw "$action" "$port/$protocol"
            ;;
    esac
}


Start_VPN_IS() {
    # 提示用户输入域名
    read -p "请输入你的域名(xxx.com/xxx.xyz/xxx.top/xxx.shop)： " VPN_Domain

    # 提示用户输入密码，并设置默认值为 123
    read -p "设置VPN密码(默认123)： " VPN_Password
    VPN_Password=${VPN_Password:-123}  # 如果用户未输入，则默认为 123

    # 停止 caddy 服务
    systemctl stop caddy.service
    if [ $? -ne 0 ]; then
        echo "停止 caddy.service 失败，请检查服务是否存在或是否已停止。"
        echo "你的服务器可能并没有运行 VPN 服务。"
        echo "已跳过关闭 VPN 服务，直接跳转到安装步骤..."
    else
        echo "caddy.service 已成功停止。"
    fi

    # 下载 easytrojan.sh 脚本
    curl -sSL https://raw.githubusercontent.com/eastmaple/easytrojan/main/easytrojan.sh -o easytrojan.sh
    if [ $? -ne 0 ]; then
        echo "下载 easytrojan.sh 脚本失败，请检查网络连接或脚本链接是否正确。"
        return 1
    fi

    # 设置脚本权限
    chmod +x easytrojan.sh
    if [ $? -ne 0 ]; then
        echo "设置脚本权限失败，请检查当前用户是否具有足够权限。"
        return 1
    fi

    # 运行 easytrojan.sh 脚本
    bash easytrojan.sh "$VPN_Password" "$VPN_Domain"
    if [ $? -ne 0 ]; then
        echo "运行 easytrojan.sh 脚本失败，请检查输入参数是否正确。"
        return 1
    fi

    # 输出 VPN 配置信息
    echo "VPN 配置信息："
    echo "域名：$VPN_Domain"
    echo "端口：443"
    echo "密码：$VPN_Password"
}


# 允许端口
allow_port() {
    read -p "请输入需要允许的端口（单个或多个，如 22 或 22,23,24）：" ports
    read -p "请输入方向（入站：in，出站：out，双向：both/IO，默认为 IO）：" direction
    direction=${direction:-io}  # 默认值改为 IO
    read -p "请输入协议类型（tcp 或 udp，默认为 tcp）：" protocol
    protocol=${protocol:-tcp}

    process_ports "$ports" "$direction" "$protocol" "allow"
}



# 禁止端口
deny_port() {
    read -p "请输入需要禁止的端口（单个或多个，如 22 或 22,23,24）：" ports
    read -p "请输入方向（入站：in，出站：out，双向：both/IO，默认为 IO）：" direction
    direction=${direction:-io}  # 默认值改为 IO
    read -p "请输入协议类型（tcp 或 udp，默认为 tcp）：" protocol
    protocol=${protocol:-tcp}

    process_ports "$ports" "$direction" "$protocol" "deny"
}

# 处理端口的通用函数
process_ports() {
    local ports=$1
    local direction=$2
    local protocol=$3
    local action=$4

    IFS=',' read -ra PORT_LIST <<< "$ports"
    for port in "${PORT_LIST[@]}"; do
        if [[ -z "$port" ]]; then
            continue
        fi

        # 检查端口是否为数字
        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
            echo "无效的端口号：$port，跳过此端口。"
            continue
        fi

        add_rule "$action" "$port" "$direction" "$protocol"
        if [ $? -eq 0 ]; then
            echo "已成功 $action 端口 $port 的 $direction 方向流量（协议：$protocol）。"
        else
            echo "操作失败，端口 $port 无法 $action。"
        fi
    done
}

# 删除规则
delete_port_rule() {
    echo "当前 UFW 规则："
    ufw status numbered
    echo
    read -p "请输入要删除的规则编号（单个或多个，如 1 或 1,2,3）：" rule_numbers

    if [[ -z "$rule_numbers" ]]; then
        echo "未输入规则编号，操作已取消。"
        return
    fi

    IFS=',' read -ra RULES <<< "$rule_numbers"
    for rule in "${RULES[@]}"; do
        if [[ -z "$rule" ]]; then
            continue
        fi
        ufw delete "$rule"
        if [ $? -eq 0 ]; then
            echo "已成功删除规则编号 $rule。"
        else
            echo "删除规则编号 $rule 失败，请检查编号是否正确。"
        fi
    done
}

# 查看当前规则
view_rules() {
    echo "当前 UFW 规则："
    ufw status verbose
}

# 恢复默认端口规则
restore_default_rules() {
    echo "正在恢复默认端口规则..."
    # 删除所有非默认端口规则
    ufw reset
    if [ $? -eq 0 ]; then
        echo "所有规则已重置。"
    else
        echo "重置规则失败，请检查 UFW 状态。"
        return
    fi

    # 允许端口 22 的入站和出站流量
    sudo ufw enable
    ufw allow in 22/tcp
    ufw allow out 22/tcp
    sudo ufw default allow incoming
    sudo ufw default allow outgoing
    if [ $? -eq 0 ]; then
        echo "默认端口规则已恢复：端口 22 的入站和出站流量已允许。"
    else
        echo "恢复默认规则失败，请检查 UFW 状态。"
    fi
}

# 主逻辑
while true; do
    show_menu
    case $choice in
        0)
            Start_VPN_IS
            ;;
        1)
            allow_port
            ;;
        2)
            deny_port
            ;;
        3)
            delete_port_rule
            ;;
        4)
            view_rules
            ;;
        99)
            echo "退出脚本。"
            exit 0
            ;;
        999)
            restore_default_rules
            ;;
        *)
            echo "无效选项，请重新输入。"
            ;;
    esac
done
