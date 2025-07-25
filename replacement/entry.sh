#!/bin/bash
# cur=$(cd "$(dirname "$0")"; pwd)
# cd $cur

# 查找所有dist目录并记录到日志
function find_all_dist() {
  echo "正在查找所有dist目录..."
  local log_file="/tmp/dist_directories.log"
  echo "开始查找: $(date)" > $log_file
  
  find / -type f -name "*webpack.*" 2>/dev/null | while read file; do
    echo "[ERROR] 找到文件: $file" >> $log_file
    echo "[ERROR] 找到文件: $file" >&2
  done
  
  echo "查找完成，结果保存在 $log_file"
  echo "总共找到 $(grep -c "dist目录" $log_file) 个dist目录"
}

function npmBuild(){
    cd /output/portainer

    # # npm
     npm -v
     npm config set registry=https://registry.npm.taobao.org -g
     npm config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass -g
     npm install --no-save webpack webpack-cli webpack-merge html-webpack-plugin copy-webpack-plugin
     # npm install -g yarn #installed
     # grunt
    #  npm install -g grunt-cli
    # grunt -h
    #npm install --prefix=/.cache grunt grunt-cli;
    # # yarn
    # yarn -v
    # yarn config set registry https://registry.npm.taobao.org -g
    # yarn config set sass_binary_site http://cdn.npm.taobao.org/dist/node-sass -g
    # .cache
    # mkdir -p /output/.cache/node_modules; rm -rf node_modules;  ln -s /output/.cache/node_modules .;
    rm -rf node_modules;  ln -s /.cache/node_modules .;
    # yarn install
    ## grunt build
    # grunt build #OK
    # npm run build
    ## grunt build prod
    rm -f webpack/webpack.production.js; cp -r /conf/webpack/ webpack/
    rm -f gruntfile.js; cp /conf/gruntfile.js gruntfile.js
    grunt devopsbuild
}

# repo
function getRepo(){
    errExit(){
        echo "$1"
        exit 1
    }
    test -z "$BRANCH" && test -z "$TAG" && errExit "BRANCH/TAG both emp, must set one"
    if [ ! -z "$BRANCH" ]; then
        test -d pt0 && (cd pt0; git fetch -t; git checkout origin/$BRANCH) || (git clone -b $BRANCH $REPO pt0; cd pt0; git checkout origin/$BRANCH) #--depth=1 
    else
        test -d pt0 && (cd pt0; git fetch origin tag $TAG; git checkout $TAG) || git clone -b $TAG $REPO pt0 #--depth=1 
    fi
}
# REPO="https://gitee.com/g-devops/fk-portainer"
# BRANCH="release/2.9"
# TAG="2.9.0" #TAG
# test -d pt0 && (cd pt0; git pull) || git clone --depth=1 -b $BRANCH $REPO pt0
getRepo

# dict portainer_zh.xml
echo -e "\n\n==get newest portainer_zh.xml============\n"
curl -qO https://gitee.com/g-devops/lang-replacement/raw/dev/output/portainer_zh.xml
cat portainer_zh.xml |wc
echo -e "已获取最新portainer_zh.xml, 请注意获取到dict的行数(避免无效数据)\n(sleep 5)\n\n\n"; sleep 5



# REPLACE
rm -rf portainer; cp -a pt0 portainer
# out app/.lang-replacement
lang-replacement ./portainer_zh.xml ./portainer/app
rm -rf .lang-replacement; mv ./portainer/app/.lang-replacement .

# 查找并记录所有dist目录
find_all_dist

# BUILD
npmBuild

# PACK
cd /output/portainer/dist; tar -zcf ./public.tar.gz public
ls -lh /output/portainer/dist/