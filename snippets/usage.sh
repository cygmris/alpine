cat compile-nginx.sh | sed '/^$/d' | sed 's/#.*$//g' | tr -s ' ' > compile-nginx-docker.sh


cat compile-nginx.sh | sed 's/#.*$//g' | sed '/^$/d' | sed ':a;N;$!ba;s/\n/ /g' > compile-nginx-docker.sh


shfmt -i 1 compile-nginx.sh
cat compile-nginx.sh | sed 's/#.*$//g' | sed '/^\s*$/d' | tr -d '\n' 


 tr -s ' ' | sed '/^$/d'


cat compressed_script.sh | tr ' ' '\n\t' | sed -e 's/^#\(.*\)$/\1/g' | sed '/./,/^$/!d' > final_script.sh


^\s+$\n