#!/bin/bash
temp_install_path="/home/gloduck/install"
env_install_path="/usr/local/lib"
app_install_path="/opt"
jdk_download_link="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.3.0/graalvm-ce-java11-linux-amd64-22.3.0.tar.gz"
maven_download_link="https://dlcdn.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz"



# 获取脚本执行用户
current_user=$(whoami)
if [ "${current_user}" = "root" ];then
    echo "请勿使用root用户运行当前脚本"
    exit 1
fi


# 创建基本文件夹，获取root权限方便后续sudo

sudo echo "开始创建基本文件夹"
# 创建环境目录
if [ ! -d ${env_install_path} ];then
    sudo mkdir -p ${env_install_path}
fi
# 创建应用安装目录
if [ ! -d ${app_install_path} ];then
    sudo mkdir -p ${app_install_path}
fi
# 创建临时安装目录
if [ ! -d ${temp_install_path} ];then
    mkdir -p ${temp_install_path}
fi
# 创建图标文件夹
if [ ! -d ${temp_install_path}/application ];then
    mkdir -p ${temp_install_path}/application
fi
cd ${temp_install_path} || exit 1




# 替换清华源
echo "替换系统源为清华源"
sudo sed -i "s@http://.*archive.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
sudo sed -i "s@http://.*security.ubuntu.com@https://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list
sudo apt update


# 移除无人值守更新功能
echo "移除无人值守更新功能"
# https://blog.csdn.net/u011198687/article/details/121576591
sudo apt autoremove -y unattended-upgrades

echo "更新内置的vim编辑器"
sudo apt remove -y vim-common
sudo apt install -y vim


echo "替换系统输入法为Fcitx"
# 重启生效，同时需要设置一下fcitx，将安装的输入法移动到最上面
# 安装后建议打开设置，把 [全局配置]的[切换激活/非激活输入法]改成Lshift
sudo apt-get install -y fcitx-googlepinyin
im-config -n fcitx
sudo apt autoremove -y ibus*
sudo apt purge -y ibus*


# 安装JDK
echo "开始安装JDK"
wget -O jdk.tar.gz ${jdk_download_link}
# 解压JDK并且获取其路径
mkdir jdk
tar -xvf jdk.tar.gz -C jdk
jdk_unzip_path=$(dirname "$(find ./jdk -name "LICENSE.txt")")
# 创建JDK根目录，并将其移入根目录
jdk_path=${env_install_path}/jdk
sudo mkdir -p ${jdk_path}
sudo mv "${jdk_unzip_path}"/* ${jdk_path}
# 写入环境变量
sudo sed -i '$a export JAVA_HOME='"${jdk_path}"'' /etc/profile
sudo sed -i '$a export PATH=$PATH:$JAVA_HOME/bin' /etc/profile




# 安装MAVEN
echo "开始安装Maven"
wget -O maven.tar.gz ${maven_download_link}
# 解压Maven并且获取其路径
mkdir maven
tar -xvf maven.tar.gz -C maven
maven_unzip_path=$(dirname "$(find ./maven -name "LICENSE")")
# 创建Maven根目录，并将其移入根目录
maven_path=${env_install_path}/maven
sudo mkdir -p ${maven_path}
sudo mv "${maven_unzip_path}"/* ${maven_path}
# 写入环境变量
sudo sed -i '$a export MAVEN_HOME='"${maven_path}"'' /etc/profile
sudo sed -i '$a export PATH=$PATH:$MAVEN_HOME/bin' /etc/profile


# 安装Idea
echo "开始安装Idea"
# 激活插件：https://plugins.zhile.io/files/ide-eval-resetter-2.1.6.zip
wget -O idea.tar.gz https://download.jetbrains.com.cn/idea/ideaIU-2021.2.1.tar.gz
mkdir idea
tar -xvf idea.tar.gz -C idea
idea_path=${app_install_path}/idea
sudo mkdir ${idea_path}
sudo mv ./idea/idea-*/* ${idea_path}
# 替换idea自带的jbr，解决光标不跟随的问题
# https://github.com/RikudouPatrickstar/JetBrainsRuntime-for-Linux-x64
sudo rm -R "${idea_path}"/jbr/*
wget -O jbr.zip https://github.com/RikudouPatrickstar/JetBrainsRuntime-for-Linux-x64/releases/download/202110301849/jbr-linux-x64-202110301849.zip
mkdir jbr
unzip -n ./jbr.zip -d ./jbr
jbr_unzip_path=$(dirname "$(find ./jbr -name "release")")
sudo mv "${jbr_unzip_path}"/* "${idea_path}"/jbr
# 写入图标文件
cat>application/idea.desktop<<EOF
[Desktop Entry]
Encoding=UTF-8
Name=IntelliJ IDEA
Comment=IntelliJ IDEA
Exec=${app_install_path}/idea/bin/idea.sh
Icon=${app_install_path}/idea/bin/idea.png
Terminal=false
StartupNotify=true
Type=Application
Categories=Application;Development;
EOF


# 安装windterm
echo "开始安装WindTerm"
wget -O windterm.tar.gz https://github.com/kingToolbox/WindTerm/releases/download/2.5.0/WindTerm_2.5.0_Linux_Portable_x86_64.tar.gz
mkdir windterm
tar -xvf windterm.tar.gz -C windterm
windterm_unzip_path=$(dirname "$(find ./windterm -name "windterm.desktop")")
windterm_path=${app_install_path}/windterm
sudo mkdir -p ${windterm_path}
sudo mv "${windterm_unzip_path}"/* ${windterm_path}
sudo chmod a+x ${app_install_path}/windterm/WindTerm
# 写入图标文件
touch application/windterm.desktop
cat>application/windterm.desktop<<EOF
[Desktop Entry]
Name=WindTerm
Comment=A professional cross-platform SSH/Sftp/Shell/Telnet/Serial terminal
GenericName=Connect Client
Exec=${app_install_path}/windterm/WindTerm
Type=Application
Icon=${app_install_path}/windterm/windterm.png
StartupNotify=true
StartupWMClass=Code
Categories=Application;Development
Keywords=windterm
Terminal=false
EOF


# 安装Jprofiler
# 注册码：
#L-J12-STALKER#5846458-y8bdm6q8gtr7b#228a
#L-J12-STALKER#8338547-qywh5933xu2r3#a4a4
echo "安装Jprofiler：https://www.ej-technologies.com/download"
wget -O jprofiler.deb https://download.ej-technologies.com/jprofiler/jprofiler_linux_12_0_4.deb
sudo apt install -y ./jprofiler.deb


# 安装破解版Dbeaver，必须优先安装JDK
# 破解教程参考：https://www.52pojie.cn/forum.php?mod=viewthread&tid=1668629&extra=&highlight=dbeaver&page=1
echo "开始安装Dbeaver"
# 下载二进制版本的dbeaver，方便破解
wget -O dbeaver.tar.gz https://dbeaver.com/files/dbeaver-ue-latest-linux.gtk.x86_64.tar.gz
mkdir dbeaver
tar -xvf dbeaver.tar.gz -C dbeaver
echo "开始破解Dbeaver"
dbeaver_crack_path=dbeaver/.jkiss-lm
mkdir ${dbeaver_crack_path}
touch ${dbeaver_crack_path}/public-key.txt ${dbeaver_crack_path}/private-key.txt
# 写入授权的公钥和密钥
echo "--- PRIVATE KEY ---
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCFfG6J3YAt9IXrzJSsfQfd7Z4n
RL0x8m5WKXWvTcz8ldO7kWCNPJR/VDkomddItrGKJu0eMAlRdGTXQL2KSzsUU144/x2IMvYpxs9N
J3LuJqkJgBrFmKUhEirQBv9mGL4fA+H3C4mT/pcSChQgLV6IqPRpUzPbkbm51ce0jHw6Nq8fZ6gV
2U6kPCbpkyPVlJuRjnRyc5vp4m/fygoXx8vhveLcnS+/mWT3Q1ilVIYXA+z1LYA2xZPUJdd+XfBA
64Ec58spOgk31Xl+oyCICg81PwG87k0wwnx30wpAPiu2qrdLjQTuIhn983nWH+RDTKcIdd2x3N7j
yND6q5KyJ8dPAgMBAAECggEATJu5JM5GfhlTspxaxxOKrEdu+MJugnfL8w8gR1ezSVMDjSZF70jR
QLIpi6+e6lBPXCYy95xB/Ml8Bj1VikTaxzOBY9ymKkB1HkzHNFRrlVoCsT0gID8WpgAzKeiaMxII
KuyjhpDMiG8YbHX0TvM6yduNSdVCccUUfh6+2lO2CAH1fRT+FJqEI8tUGbuB16YvM6t/mNjtbOo1
dSsRacc/7fV3vPP7a3kqc0PHpIDAyuKcLWn1HwEzBeAgp/TlX9J1bU8WcijKQBLcrxYmxAqDZOPD
imcV0XfKs6I2JUHEePUHiAoG59BhVGA/rJnkyQEpaD3mKkFImIIKm6poLvzboQKBgQD1iLWE4gKe
g/5TUAFO/aMhiMQG3vP410eBoWHZnvQt72VKX6hlgGwvZld1UF7hqljK1ICvvwFe2aGWDJAk5Zz5
0ipPj1UVkk5FsLoi/YT3Pj8tsNT0xJrilXDlpYAEsecbqvBs5QBGBKH+4QkFoCvCb6qWuDWQMNYJ
Ja/Su97nLQKBgQCLLQtqRutmw96XzkfV9yuqQ9nzk7Z7CfM00O4l0jP0tKTXomuSW1nRiYc3UfZJ
cJfPR91y40N4v7A8DaiReH5T5F6Mt6gnnSmRt/J6vE5tz3lODnoaUVOmjEpj7ytQdtr2xUYNOnEu
oRH2lPkhUdIBM35EfySpKBu7yWfc3ap16wKBgQDGZzKububI6kWvUp3ME34nUdl859njASph4GMu
M5iCKckCgSuU4WIKJzuSq2AQH9NiCrb1zHUyDM/abMppVjUzVZUk9uA87x1aiQTP02YHV4A7zoE2
TEwPvcwddU9t+8eQ/t8KTz2aVpIEYBknN5dEpXEGG1IE8sFxYMejlHX4/QKBgECo/NSzfkqQVapR
vC48V50TSP9RcUZYqRWwu/P2ZQ0boDpOy4uDxYcETj31ZmdYWC+FQ+1MiNxgspA0CE0NniN7xjG6
YfWFnvqEa7N6KTX7XnBVaYUwo5yNMUKcq5MGpVRg8trSfCMd0iqtq9E/IkJMmi1YpL+yUrA8MnT6
x2dhAoGBALSWWmS3fBhUi55YwnmxMGcZKRw3SR4qvgfMVsXx/wraLg6HdHYv5eugQ5JimqlAw6Bv
B6EIBnhrWT41s1uLkVrD3bYvOT5dKlgHmNUuosZdTkAZQAptiPq0tNnXJ5N++4NIf4vmTgbC4OhG
b5eH0TuNW8cBSErqYoCf/tVrjVTq" > ${dbeaver_crack_path}/private-key.txt
echo "--- PUBLIC KEY ---
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhXxuid2ALfSF68yUrH0H3e2eJ0S9MfJu
Vil1r03M/JXTu5FgjTyUf1Q5KJnXSLaxiibtHjAJUXRk10C9iks7FFNeOP8diDL2KcbPTSdy7iap
CYAaxZilIRIq0Ab/Zhi+HwPh9wuJk/6XEgoUIC1eiKj0aVMz25G5udXHtIx8OjavH2eoFdlOpDwm
6ZMj1ZSbkY50cnOb6eJv38oKF8fL4b3i3J0vv5lk90NYpVSGFwPs9S2ANsWT1CXXfl3wQOuBHOfL
KToJN9V5fqMgiAoPNT8BvO5NMMJ8d9MKQD4rtqq3S40E7iIZ/fN51h/kQ0ynCHXdsdze48jQ+quS
sifHTwIDAQAB" > ${dbeaver_crack_path}/public-key.txt
# 替换jar包中的公钥
dbeaver_crack_jar=$(ls dbeaver/dbeaver/plugins/com.dbeaver.app.ultimate_*.jar)
dbeaver_crack_target=$(${jdk_path}/bin/jar -tvf "${dbeaver_crack_jar}" | grep dbeaver-ue-public.key | awk '{print $8}')
${jdk_path}/bin/jar -xvf "${dbeaver_crack_jar}" "${dbeaver_crack_target}"
cat ${dbeaver_crack_path}/public-key.txt > keys/dbeaver-ue-public.key
${jdk_path}/bin/jar -uvf "${dbeaver_crack_jar}" "${dbeaver_crack_target}"
rm -R keys
# 配置文件添加项
sed -i '$a -Dlm.debug.mode=true' dbeaver/dbeaver/dbeaver.ini
# 生成订阅文件
touch ${dbeaver_crack_path}/dbeaver-ee.lic ${dbeaver_crack_path}/dbeaver-ue.lic
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<product id=\"dbeaver-ee\">
    <license type=\"standard\">KDD05eUkmg913Vq5Id1WAvNttGYHaNev0o+RSe0UTFY2ThGy/Notx/ZX2gxG7OZkowsao9gGUKTWQlEjovYdIYW9VcyDnoCRHSLu/xEZ2nTT7O43FJWTDpTRQ/9/9H4UKihQN7gfIwD4aIy80ojQmuF0TPvdUS6zhzbEeErwICQl91bR9dgfaxV7Ilbr4ZnS1bSZC78LJci9WRZv7Yjj/9yB0Pi7hLc3mk5M305ZP40VpNRbXZmB4BZljsWD8ZhcS00EYWlFKxjI6JPoFyLhKSbn2wyal47Q7tpO1sCswD6z4TKl3QP0so76F/GYjbuAP8AINuCJBip74deJtXV3BA==</license>
</product>" > ${dbeaver_crack_path}/dbeaver-ee.lic
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<product id=\"dbeaver-ue\">
  <license type=\"standard\">ReJalXttbssteHQ63re1sGcW2XbP4emJiJxLGaa/JEXXcRiuUzwfwAHh5gUWD+blYrIVKy4Ibx9kxm6XcIlg4X1eWI4UrlTep+D5l2cKSqw63Hzi8hyau8H9OFfPe9PHig1Kla+u4fQCkn7AidqZPkV7QVK2F++ZIUcPmc+qEkm3suOEtRgEKKBfsZpHTg+CUrUb37DlEz6qWnOI+5hy95B3z892TTJzkARcHOhSdFM/1/q4WMUtfjcVcav7x7qiFDIfuWQsMNASVMxBJtbKsKv9tqc+2ExGV+9bZBHls7JehGOWbG7YOpoZA49Ha6DnWlhoWAeFizL6zFLbH8+tZQ==</license>
</product>" > ${dbeaver_crack_path}/dbeaver-ue.lic
# 移动订阅文件、公钥密钥到用户目录
mv ${dbeaver_crack_path} ~
# 移动Dbeaver到安装目录
sudo mv dbeaver/* ${app_install_path}
# 写入图标文件
touch application/dbeaver.desktop
cat>application/dbeaver.desktop<<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Dbeaver
Comment=Dbeaver Database Util
Exec=${app_install_path}/dbeaver/dbeaver
Icon=${app_install_path}/dbeaver/dbeaver.png
Terminal=false
StartupNotify=true
Type=Application
Categories=Application;Development;
EOF


# 安装ApiFox
echo "安装ApiFox：https://www.apifox.cn/"
wget -O apifox.zip https://cdn.apifox.cn/download/Apifox-linux-deb-latest.zip
mkdir apifox
unzip -n ./apifox.zip -d ./apifox
sudo apt install -y ./apifox/apifox_*.deb


# 安装Qv2ray
echo "安装qv2ray"
# 安装libfuse2，否则无法运行AppImage
sudo add-apt-repository -y universe
sudo apt install -y libfuse2
qv2ray_path=${app_install_path}/qv2ray
sudo mkdir -p ${qv2ray_path}
mkdir -p qv2ray/core
wget -O ./qv2ray/qv2ray.AppImage https://github.com/Qv2ray/Qv2ray/releases/download/v2.7.0-pre1/Qv2ray.v2.7.0-pre1.linux-x64.AppImage
sudo chmod 777 ./qv2ray/qv2ray.AppImage
wget -O ./qv2ray/core.zip https://github.com/v2fly/v2ray-core/releases/download/v4.44.0/v2ray-linux-64.zip # 不支持高版本的v2ray核心
unzip -n ./qv2ray/core.zip -d ./qv2ray/core
rm ./qv2ray/core.zip
# 下载图标
wget -O qv2ray.png https://raw.githubusercontent.com/Qv2ray/Qv2ray/dev/assets/icons/qv2ray.128.png
mv qv2ray.png qv2ray
# 移动到软件目录
sudo mv qv2ray/* ${qv2ray_path}
# 写入图标文件 
touch application/qv2ray.desktop
cat>application/qv2ray.desktop<<EOF
[Desktop Entry]
Encoding=UTF-8
Name=qv2ray
Comment=V2ray UI Client
Exec=${qv2ray_path}/qv2ray.AppImage
Icon=${qv2ray_path}/qv2ray.png
Terminal=false
StartupNotify=true
Type=Application
Categories=Application;
EOF
# 写入配置文件
mkdir -p ~/.config/qv2ray
touch ~/.config/qv2ray/Qv2ray.conf
cat>~/.config/qv2ray/Qv2ray.conf<<EOF
{
    "advancedConfig": {
    },
    "autoStartBehavior": 0,
    "autoStartId": {
    },
    "config_version": 14,
    "defaultRouteConfig": {
        "dnsConfig": {
            "servers": [
                {
                    "address": "1.1.1.1"
                },
                {
                    "address": "8.8.8.8"
                },
                {
                    "address": "8.8.4.4"
                }
            ]
        }
    },
    "inboundConfig": {
        "socksSettings": {
            "port": 1089
        }
    },
    "kernelConfig": {
        "v2AssetsPath_linux": "${qv2ray_path}/core",
        "v2CorePath_linux": "${qv2ray_path}/core/v2ray"
    },
    "lastConnectedId": {
    },
    "logLevel": 3,
    "networkConfig": {
    },
    "outboundConfig": {
    },
    "pluginConfig": {
    },
    "uiConfig": {
        "language": "zh_CN"
    },
    "updateConfig": {
    }
}
EOF


# 安装docker
echo "开始安装docker"
sudo apt install -y docker.io
sudo groupadd docker
sudo gpasswd -a "${current_user}" docker
sudo service docker restart




# 安装Stacer（清理软件）
echo "安装Stacer"
sudo apt install -y stacer


# 安装Typora
echo "安装破解版Typora"
# 正版安装命令
# wget -qO - https://typoraio.cn/linux/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/typora.asc
# sudo add-apt-repository -y 'deb https://typoraio.cn/linux ./'
# sudo apt-get update
# sudo apt-get install typora
# 破解版安装命令（输入任意邮箱和序列号即可激活）
# 如需要其他版本，可以去仓库：https://github.com/Gloduck/ubuntu_install/tree/main/source/typora
wget -O typora.deb https://raw.githubusercontent.com/Gloduck/ubuntu_install/main/source/typora/typora_lastest_amd64.deb
sudo apt install -y ./typora.deb



# 安装Utools
echo "安装Utools"
wget -d --header="User-Agent: Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11" -O utools.deb https://res.u-tools.cn/version2/utools_3.3.0_amd64.deb
sudo apt install -y ./utools.deb
# 如果是ubuntu22.04，则需要额外的操作
wget -O openssl.pkg.tar.zst https://archlinux.org/packages/core/x86_64/openssl-1.1/download/
tar xvf openssl.pkg.tar.zst
sudo cp usr/lib/libcrypto.so.1.1 /opt/uTools/
# 加入开启自启
mkdir -p ~/.config/autostart
touch ~/.config/autostart/utools.desktop
cat /usr/share/applications/utools.desktop >> ~/.config/autostart/utools.desktop


# 卸载内置的firefox并且安装谷歌浏览器
echo "卸载内置的firefox并安装谷歌浏览器"
sudo snap remove firefox
wget -O chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./chrome.deb


# 安装QQ
echo "安装Linux原生QQ"
wget -O qq.deb https://dldir1.qq.com/qqfile/qq/QQNT/4b2e3220/linuxqq_3.1.0-9572_amd64.deb
sudo apt install -y ./qq.deb

# 安装微信
echo "安装Linux原生微信"
wget -O wechat.deb https://archive.ubuntukylin.com/software/pool/partner/weixin_2.1.4_amd64.deb
sudo apt install -y ./wechat.deb

# 安装优麒麟版企业微信
echo "安装优麒麟版企业微信"
wget -O ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
wget -O wxwork.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
sudo apt install -f -y ./ukylin-wine.deb
sudo apt install -f -y ./wxwork.deb


# 安装洛雪音乐播放器
echo "安装洛雪音乐播放器"
# Git地址：https://github.com/lyswhut/lx-music-desktop
wget -O lx-music.deb https://github.com/lyswhut/lx-music-desktop/releases/download/v2.1.2/lx-music-desktop-v2.1.2-x64.deb
sudo apt install -y ./lx-music.deb

# 安装vlc播放器
sudo apt install -y vlc

# 安装星火商店
echo "安装星火商店"
wget -O spark.deb https://gitee.com/deepin-community-store/spark-store/releases/download/4.2.3test4/spark-store_4.2.3~test4_amd64.deb
sudo apt install -y ./spark.deb

# 安装腾讯会议
#https://zhuanlan.zhihu.com/p/546516064
#wget -O tencent-metting.deb https://updatecdn.meeting.qq.com/cos/e078bf97365540d9f0ff063f93372a9c/TencentMeeting_0300000000_3.12.0.400_x86_64_default.publish.deb
#sudo apt install -y ./tencent-metting.deb


# 安装Crossover
# echo "安装Crossover22"
# wget -O crossover.deb https://cpv2.mairuan.com/crossoverchina.com/trial/Linux/crossover-22.deb
# sudo apt install -y ./crossover.deb



# 安装一些常用的Win软件
# 导入Deepin移植仓库
# wget -O- https://deepin-wine.i-m.dev/setup.sh | sh

# 安装wine运行器
# https://gitee.com/gfdgd-xi/deep-wine-runner/
# wget -O wine-runner.deb https://gitee.com/gfdgd-xi/deep-wine-runner/releases/download/2.4.1/spark-deepin-wine-runner_2.4.1_all.deb
# sudo apt install -y ./wine-runner.deb
# 下载常用wine软件
# 企业微信：wget -O wx.exe https://dldir1.qq.com/wework/work_weixin/WeCom_3.1.6.3605.exe
# qq轻聊版：wget http://dldir1.qq.com/qqfile/qq/QQ7.9Light/14308/QQ7.9Light.exe 




# 优麒麟软件
# https://archive.ubuntukylin.com/software/pool/partner/


# 修改系统时间，防止双系统下时间不正确
sudo timedatectl set-local-rtc 1 --adjust-system-clock




# 移动图标文件到图标文件夹
echo "开始移动图标到图标文件夹"
sudo chmod 644 application/*.desktop
sudo chown root.root application/*.desktop
sudo mv application/*.desktop /usr/share/applications




echo "清理安装过程中产生的临时文件"
sudo rm -R ${temp_install_path}



# 清屏，并且显示提示内容
# clear
