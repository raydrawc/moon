#/usr/bin/env bash
#-------------------------------------------
# 引导程序
# @auther raydrawc@gmail.com
#-------------------------------------------

# 检测运行环境
get_env_os(){
    local unameout="$(uname -s)"
    # 主要用于配置lua编译
    case "${unameout}" in
        Linux*)     PLATFORM=linux;;
        Darwin*)    PLATFORM=macosx;;
        CYGWIN*)    PLATFORM=mingw;;
        MINGW*)     PLATFORM=mingw;;
        *)          PLATFORM=generic;;
    esac
}

# 配置运行环境
get_env_os

# copy dep
git clone git@github.com:raydrawc/lua_nif_dep.git dep
cd dep && ./decode.sh

# if you use luajit and you can use this
cd lua/src/ && make

# if you use lua.org and you can use this
# cd lua/src/ %% make ${PLATFORM}