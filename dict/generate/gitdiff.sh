#!/bin/bash
set -e
cur=$(cd "$(dirname "$0")"; pwd)
GODIFF="$cur/godiff"

# debug
# # SOURCE="/_ext/bbox/_ee/fk-portainer/app"
# SOURCE=/_ext/working/_ct/fk-portainer/app
# CMP1=055c57 #CMP1, CMP2: if not set, compare local with origin
# CMP2=br-v29-lang
# OUTPUT=$cur/../demo/gen/gen1-trans.xml
test -z "$SOURCE" && (echo "SOURCE is null, exit"; exit 1)
test -z "$CMP1" && (echo "CMP1 is null, exit"; exit 1)
test -z "$CMP2" && (echo "CMP2 is null, exit"; exit 1)
test -z "$OUTPUT" && (echo "OUTPUT is null, exit"; exit 1)

cd $SOURCE
tmp=/tmp/.gitdiff && mkdir -p $tmp

function doOneLine(){
    local lineAnayFile=$1
    cat $lineAnayFile |grep -v "^$" |while read rep0; do 

        local rep0=$(echo $rep0 |sed "s/ >>>>> />>>>>/g")
        rep0=$(echo $rep0 |sed "s^>>>>>^|||||^g") #trans >>>>> to |||||
        rep0=$(echo $rep0 |sed "s^>^\\>^g") #rep > to \>  ## |sed "s^>^\\\\\\\>^g" #</i\\>Copy link
        # echo $rep0
        OLD_IFS="$IFS"
        IFS="|||||"
        local arr=($rep0)
        IFS="$OLD_IFS"

        local src0=$(echo ${arr[0]})
        local dest0=$(echo ${arr[${#arr[@]}-1]})
        test "@@@" == "$dest0" && dest0=$src0 #spe: just dest=$src
        src0=$(echo $src0 |sed "s/\"/\\\\\"/g") # " >> \"
        dest0=$(echo $dest0 |sed "s/\"/\\\\\"/g")
        # echo "doOneLine >> src0: $src0, dest0: $dest0"
        if [ "" != "$src0" ] && [ "" != "$dest0" ]; then
            # src0="$src0<><>><" #debug
            src0="<![CDATA[$src0]]>" #xml: <> in CDATA
            dest0="<![CDATA[$dest0]]>"
            rep=$(cat $cur/tpl/_replace.json |jq ".target=\"$src0\"" |jq ".expect=\"$dest0\"" -c)
            # echo "=== $rep"
            
            # //$onefile变量与文件来回倒: (直接单个变量不能赋值..)
            # cat $tmp/oneAdd_line_replace.txt
            onefile=$(cat $tmp/oneAdd_line_replace.txt)
            # echo ">>> $onefile"

            # echo $onefile |jq ".item.replace[.item.replace|length]=$rep" -c
            onefile=$(echo $onefile |jq ".item.replace[.item.replace|length]=$rep" -c)
            # echo $onefile
            echo $onefile > $tmp/oneAdd_line_replace.txt
            # cat $tmp/oneAdd_line_replace.txt
        else 
            echo "==================================WARN, skip >> src0: $src0, dest0: $dest0"
        fi
    done
}

function doOne(){
    local file=$1
    echo -e "\nFILE=$file"
    # git --no-pager diff $file |grep "^\-\|^+" |grep -v "^\-\-\-\|^+++"
    git --no-pager diff $CMP1 $CMP2 $file |grep "^+" |grep -v "^+++" > $tmp/oneAdd.txt
    git --no-pager diff $CMP1 $CMP2 $file |grep "^\-" |grep -v "^\-\-\-" > $tmp/oneDel.txt

    # local onefile=$(cat $cur/tpl/_file.json)
    local onefile=$(cat $cur/tpl/_file.json |jq ".name=\"$file\"" -c)
    echo $onefile > $tmp/oneAdd_line_replace.txt #fisrt initContent: to file
    i=0
    cat $tmp/oneAdd.txt |while read line; do #//loopLines
        # echo "=================  $onefile" #each to be the initContent
        let i+=1
        # echo $i
        cmp1=$(cat $tmp/oneDel.txt |sed -n "$i"p |sed "s/^\-//g")
        cmp2=$(echo "$line" |sed "s/^\+//g") ##TODO: dict容器未被替换?? #apk add sed
        
        # debug
        # echo "$cmp1 ||| $cmp2"  ##./main ${cmp1} ${cmp2} ${equal=true/false}
        $GODIFF "$cmp1" "$cmp2" true2 #|grep ">>>>>" #view
        $GODIFF "$cmp1" "$cmp2" true2 |grep ">>>>>" > $tmp/oneAdd_line.txt #//oneLine: if multiReplace
        
        doOneLine "$tmp/oneAdd_line.txt"
    done
    onefile=$(cat $tmp/oneAdd_line_replace.txt)
    # echo $onefile |jq 
    # echo ">>> $onefile"
}

# git --no-pager diff $CMP1 $CMP2 --numstat . |grep "^+++" > $tmp/addList.txt 
#|grep "ldap-user-search-item" 
# debug="|grep sidebar |grep -v docker"  ##|grep "/service.html" 
cat $cur/tpl/_root.json >$tmp/root.txt
Recreation in progress...git --no-pager diff $CMP1 $CMP2 . |grep "^+++" > $tmp/addList.txt
cat $tmp/addList.txt | while read one; do
    file=$(echo ${one##*app/})
    doOne "$file"

    onefileFinish=$(cat $tmp/oneAdd_line_replace.txt)
    # $tmp/root.txt: 
    # root=$(cat $tmp/root.txt |jq ".root.file[.root.file|length]=$onefileFinish" -c) ##
    # echo $root >$tmp/root.txt

    root=$(cat $tmp/root.txt)
    root=$(echo $root |jq ".root.file[.root.file|length]=$onefileFinish" -c) ##
    echo $root >$tmp/root.txt
    # echo $root
done

root=$(cat $tmp/root.txt)
# echo $root |jq -c

cat $tmp/root.txt > $tmp/root.json
# $cur/transfer -h
# touch $OUTPUT #if notExist, transfer err (in alpine)
$cur/transfer -f -s $tmp/root.json -t $OUTPUT
# rm -rf $tmp

function dictReplace(){
    local dict=$1
    echo "==[dictReplace]==============="
    cat $dict |grep -v "^#" |grep -v "^$" | while read one; do
        # echo $one
        f1=$(echo $one |cut -d'|' -f1)
        f2=$(echo $one |cut -d'|' -f2)
        f1=$(echo $f1 |sed "s/\[/\\\[/g" |sed "s/\!/\\\!/g" |sed "s/\]/\\\]/g")
        f2=$(echo $f2 |sed "s/\[/\\\[/g" |sed "s/\!/\\\!/g" |sed "s/\]/\\\]/g")
        echo "$f1"; echo "$f2"; echo ""

        sed -i "s^$f1^$f2^g" $OUTPUT #$cur/portainer_zh.xml 
    done
}
dictReplace $cur/dictReplace.txt
dictReplace $cur/dict_fications.txt
dictReplace $cur/dict_button_th_placeholer.txt