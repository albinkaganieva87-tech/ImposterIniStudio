#!/bin/bash

# (C) ABOBIX INCORPORATE, 12y

# КОДЫ СООБЩЕНИЯ И ИХ ТИПЫ
# ======ТИПЫ СООБЩЕНИЙ ПАРСЕРА=====

# _PARSE_DEBUG_MESS		уровень критичности: 0				класс: отладочное сообщение парсера
# INI_PARSE_WARNING_N		уровень критичности: 0. иногда 1 	класс: предупреждения парсера
# INI_PARSE_ERROR_N 	    уровень критичности: 2				класс: критические ошибки парсера

# =====КОДЫ ПРЕДУПРЕЖДЕНИЙ====
# ПРЕДУПРЕЖДЕНИЯ

# INI_PARSE_WARNING_0 	 SECTION IS N'T EXISTS, SO PARSER CREATED SECTION AND CREATED KEY $key WITH VALUE '$value'
# INI_PARSE_WARNING_1    INI_PARSE_WARNING_1: KEY ISN'T EXISTS, SO PARSER CREATED KEY IN SECTION $section WITH VALUE 'NULL'

# ОШИБКИ

# INI_PARSE_ERROR_0 	INI_PARSE_ERROR_0: NAME CAN'T BE NULL
# INI_PARSE_ERROR_1 	INI_PARSE_ERROR_1: SECTION WITH THIS NAME ALREADY EXISTS ($name)
# INI_PARSE_ERROR_4     INI_PARSE_ERROR_4: SECTION [$name] NOT FOUND
# INI_PARSE_ERROR_5	    INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL
# INI_PARSE_ERROR_6     INI_PARSE_ERROR_6: SECTION IS N'T EXISTS
# INI_PARSE_ERROR_7    	INI_PARSE_ERROR_7: KEY '$key' NOT FOUND IN SECTION '$section'
# INI_PARSE_ERROR_8     INI_PARSE_ERROR_8: EMPTY COMMENT
# INI_PARSE_ERROR_9     INI_PARSE_ERROR_9: EMPTY STRING
# INI_PARSE_ERROR_10    INI_PARSE_ERROR_10: STRING '$str' NOT FOUND
# INI_PARSE_ERROR_11	INI_PARSE_ERROR_11: VARIABLE VITH THIS NAME ALSO DECLARED
# INI_PARSE_ERROR_12 	INI_PARSE_ERROR_12: VARIABLE VITH THIS NAME ISN'T EXISTS

# ТЕПЕРЬ К ЛОГИКЕ

# здесь переменная пути к файлу 
# ее можно будет изменить через , либо напрямую
ini="config.ini"
readonly VERSION="2.0"
readonly BUILDING=11
declare -gA variables
# здесь будут цвета
C_SEC="\e[1;92m"  
C_KEY="\e[1;36m"  
C_VAL="\e[1;93m"  
C_RES="\e[0m"    

# для однострочников 
ogetini() {
    local section=$1 key=$2
    awk -F '=[ ]*' -v sk="$C_KEY" -v sv="$C_VAL" -v sr="$C_RES" \
    "/\[$section\]/{a=1} a==1 && \$1 == \"$key\"{print sk \$1 sr \" = \" sv \$2 sr; exit} /^\[/ && !/\[$section\]/{a=0}" "$ini"
}

# для многострочников
mgetini() {
    local section=$1 key=$2
    awk -v target_sec="[$section]" -v target_key="$key" \
        -v sk="$C_KEY" -v sv="$C_VAL" -v sr="$C_RES" '
    BEGIN { FS="=[ ]*"; in_sec=0; flag=0 }
    $0 ~ /^\[.*\]$/ { in_sec = ($0 == target_sec); next }
    in_sec && $1 == target_key {
        printf "%s%s%s = %s%s", sk, $1, sr, sv, $2
        flag = 1; next
    }
    in_sec && flag && /^[ \t]+/ {
        printf "\n%s", $0; next
    }
    /^[a-zA-Z0-9_-]/ || /^\[/ { flag = 0 }
    END { printf "%s\n", sr } 
    ' "$ini" | sed 's/^[ \t]*//' | sed '/^$/d'
}

# для получения секции
getsect() {
    local section=$1
    local block
    block=$(sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep '=')
    echo -e "${C_SEC}[$section]${C_RES}"
    while IFS='=' read -r k v; do
        k=$(echo "$k" | xargs)
        v=$(echo "$v" | xargs)
        echo -e " ${C_KEY}${k,,}${C_RES} = ${C_VAL}${v}${C_RES}"
        printf -v "${section}_$k" "%s" "$v"      
    done <<< "$block"
}



# для получения всего ini
# рекомендуется
fgetini() {
    declare -gA ini_data
    local current_section=""
    
    local green="\e[1;92m"  
    local cyan="\e[1;36m"  
    local yellow="\e[1;93m" 
    local reset="\e[0m"

    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)
        
        [[ -z "$key" || "$key" =~ ^[#\;] ]] && continue
        
        if [[ "$key" =~ ^\[(.+)\]$ ]]; then
            current_section="${BASH_REMATCH[1]}"
            echo -e "${green}[$current_section]${reset}"
        else
            value=$(echo "$value" | xargs)
            ini_data["$current_section.$key"]="${yellow}$value${reset}"
            
            echo -e "  ${cyan}$key${reset} = ${yellow}$value${reset}"
        fi
    done < "$ini"
}

# функция смены пути
# setini новый_путь
setini() {
    ini="$1" 
}

# вывести путь
echoi(){
	echo "$ini"
}
# выводит версию
echov(){
	echo $VERSION
}

echob(){
	echo $BUILDING
}
# создаст секцию
# newSection имя_секции
newSection() {
    local name=$1
    
    if [[ -z "$name" ]]; then
        echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL"
        return 1
    fi

    if grep -q "^\[$name\]$" "$ini" 2>/dev/null; then
        echo "INI_PARSE_ERROR_1: SECTION WITH THIS NAME ALREADY EXISTS ($name)"
    else
        echo -e "\n[$name]" >> "$ini"
        echo "INI_PARSE_DEBUG_MESS: SECTION [$name] CREATED"
    fi
}

# удалит секцию
# delSection имя_секции
delSection() {
    local name=$1
    
    if [[ -z "$name" ]]; then
        echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL"
        return 1
    fi
    if grep -q "^\[$name\]$" "$ini"; then        
        sed -i "/^\[$name\]/,/^\s*\[/{ /^\[$name\]/d; /^\s*\[/!d }" "$ini"        
        echo "INI_PARSE_DEBUG_MESS: SECTION [$name] DELETED"
    else
        echo "INI_PARSE_ERROR_4: SECTION [$name] NOT FOUND"
    fi
}

# создаст пару ключ-значение в секции
# createInSec имя_секции имя_ключа значение_ключа
createInSec(){
	local section=$1
	local key=$2
	local value=$3
	if [[ -z "$section" ]]; then
		echo "INI_PARSE_ERROR_0: NAME OF SECTION CAN'T BE NULL"
		return 1
	fi
	
	if [[ -z "$key" ]]; then
		echo "INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL"
		return 1
	fi

	if [[ -z "$value" ]]; then 
		echo "INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL"
		return 1	
	fi

	if [[ ! -f "$ini" ]]; then
	        touch "$ini"
	fi
	
	if ! grep -q "^\[$section\]$" "$ini"; then
	 {
	     echo -e "\n[$section]"
	     echo "$key=$value"
	 } >> "$ini"
	else
		if sed -n "/^\[$section\]/,/^\[/p" "$ini" | grep -q "^$key[[:space:]]*="; then
	         setkey "$section" "$key" "$value"
	   	else
	          sed -i "/^\[$section\]/a $key=$value" "$ini"
	     fi
	fi
	
}

# изменит значение по ключу
# setkey имя_секции имя_ключа новое_значение
setkey(){
	local section=$1
	local key=$2
	local value=$3

	if [[ -z "$section" ]]; then
		echo "INI_PARSE_ERROR_0: NAME OF SECTION CAN'T BE NULL"
		return 1
	fi
		
	if [[ -z "$key" ]]; then
		echo "INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL"
		return 1
	fi
	
	if [[ -z "$value" ]]; then 
		echo "INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL"
		return 1	
	fi
	
	if [[ ! -f "$ini" ]]; then
		touch "$ini"
	fi
	
	if ! grep -q "^\[$section\]$" "$ini"; then
        echo -e "\n[$section]\n$key=$value" >> "$ini"
        echo "INI_PARSE_WARNING_0: SECTION IS N'T EXISTS, SO PARSER CREATED SECTION AND CREATED KEY $key WITH VALUE '$value'"
        return 0
    fi

    if sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep -q "^$key[[:space:]]*="; then
        sed -i "/^\[$section\]/,/^\s*\[/ s|^\($key\s*=\s*\).*|\1$value|" "$ini"
    else
        sed -i "/^\[$section\]/a $key=$value" "$ini"
    fi

}

# выведет значенние ключа по имени и секции
# echokey имя_секции имя_ключа
echokey(){
	local section=$1
	local key=$2	
	if [[ -z "$section" ]]; then
			echo "INI_PARSE_ERROR_0: NAME OF SECTION CAN'T BE NULL"
			return 1
	fi
			
	if [[ -z "$key" ]]; then
		echo "INI_PARSE_ERROR_5: KEY CAN NOT BE NULL"
		return 1
	fi
		
	if [[ ! -f "$ini" ]]; then
		touch "$ini"
	fi
		
    if [[ ! -z $variables[$name] ]]; then
		if ! grep -q "^\[$section\]$" "$ini"; then
	      echo -e "\n[$section]\n$key=null" >> "$ini"
	      echo "INI_PARSE_WARNING_0: SECTION IS N'T EXISTS, SO PARSER CREATED SECTION AND CREATED KEY WITH VALUE 'NULL'"
	      return 0
		fi
			local value=$(sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep "^$key[[:space:]]*=" | cut -d'=' -f2- | xargs)
    	if [[ -n "$value" ]]; then
        	echo "$value"
    	else
        	sed -i "/^\[$section\]/a $key=null" "$ini"
        	echo "null"
        	echo "INI_PARSE_WARNING_1: KEY ISN'T EXISTS, SO PARSER CREATED KEY IN SECTION $section WITH VALUE 'NULL'" >&2
    	fi
    else 
    	if ! grep -q "^\[$section\]$" "$ini"; then
    	    echo -e "\n[$section]\n$key=null" >> "$ini"
    	    echo "INI_PARSE_WARNING_0: SECTION IS N'T EXISTS, SO PARSER CREATED SECTION AND CREATED KEY WITH VALUE 'NULL'"
    	    return 0
    	fi
    	local value=$(sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep "^$key[[:space:]]*=" | cut -d'=' -f2- | xargs)
    
        if [[ -n "$value" ]]; then
            echo "$value"
        else
            sed -i "/^\[$section\]/a $key=null" "$ini"
            echo "null"
            echo "INI_PARSE_WARNING_1: KEY ISN'T EXISTS, SO PARSER CREATED KEY IN SECTION $section WITH VALUE 'NULL'" >&2
        fi
    fi
}

# выведет все секции из файла
# echosect
echosect(){
    if [[ ! -f "$ini" ]]; then
        touch "$ini"
    fi
    if ! grep -q "\[.*\]" "$ini"; then
        echo "INI_PARSE_DEBUG_MESS: NO SECTIONS IN FILE $ini ."
        return 0
    else
        local sect_list=$(grep -o "\[[^]]*\]" "$ini" | sed 's/[\[\]]//g')
        declare -gA sections
        NUM=0
        for s in $sect_list; do
            sections["$NUM"]="$s"
            echo "$s"
            (( NUM++ ))
        done
    fi
}

# выведет все ключи со значениями
# echokv
echokv(){
	if [[ ! -f "$ini" ]]; then
	    touch "$ini"
	fi
	if ! grep -q "=" "$ini"; then
	    echo "INI_PARSE_DEBUG_MESS: NO KEYS/VALUES IN FILE $ini ."
	    return 0
	else
		local NUM=0
		declare -gA kv
		local keys_list=$(grep -v '^[#;]' "$ini" | grep '=')
		IFS=$'\n'
		for k in $keys_list; do
			local cl=$(echo "$k" | sed 's/ *= */=/')
			kv["$NUM"]="$cl"
			echo "$cl" 
			(( NUM++ ))
		done
	fi
}

# УДАЛИТ КЛЮЧ-ЗНАЧЕНИЕ ИЗ СЕКЦИИ
# delkv имя_секции имя_ключа
delkv(){
	local section=$1
	local key=$2
	
	if [[ ! -f "$ini" ]]; then
	    touch "$ini"
	fi

	if [[ -z "$section" ]]; then
		echo "INI_PARSE_ERROR_0: NAME OF SECTION CAN'T BE NULL"
		return 1
	fi
				
	if [[ -z "$key" ]]; then
		echo "INI_PARSE_ERROR_5: KEY CAN NOT BE NULL"
		return 1
	fi
	
	if ! grep -q "=" "$ini"; then
		 echo "INI_PARSE_DEBUG_MESS: NO KEYS/VALUES IN FILE $ini ."
		 return 0
	fi

	if ! grep -q "\[.*\]" "$ini"; then
	    echo "INI_PARSE_DEBUG_MESS: NO SECTIONS IN FILE $ini ."
	    return 0
	fi

	if ! grep -q "^\[$section\]$" "$ini"; then
		echo "INI_PARSE_ERROR_6: SECTION IS N'T EXISTS"
		return 1
	fi
	
	if sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep -q "^$key[[:space:]]*="; then
		sed -i "/^\[$section\]/,/^\s*\[/ { /^$key[[:space:]]*=/d }" "$ini"
		echo "INI_PARSE_DEBUG_MES: KEY '$key' DELETED FROM SECTION '$section'"
	else
		echo "INI_PARSE_ERROR_7: KEY '$key' NOT FOUND IN SECTION '$section'"
		return 1
	fi
	
}

# создаст комментарий
# crcom строка "комментарий" (1/2)
crcom(){
	local str=$1
	local comment=$2
	local type=$3
	local startwith=$4
	if [[ -z $str ]]; then
		echo "INI_PARSE_ERROR_9: EMPTY STRING"
	fi
	
	if [[ -z $comment ]]; then
		echo "INI_PARSE_ERROR_8: EMPTY COMMENT"
		return 1;
	fi
	if [[ $startwith == "--hashtag" ]]; then
		if [[ $type == 1 ]]; then # в конец строки
			if grep -q "^$str" "$ini"; then
	   			sed -i "/^$str/ s|$| ; $comment|" "$ini"
	   			echo "INI_PARSE_DEBUG: COMMENT ADDED TO LINE '$str'"
			else
	    		echo "INI_PARSE_ERROR_10: STRING '$str' NOT FOUND"
				return 1
			fi
		fi
	
		if [[ $type == 2 ]]; then # перед строкой
			if grep -q "^$str" "$ini"; then
	        	sed -i "/^$str/i ; $comment" "$ini"
	        	echo "INI_PARSE_DEBUG: COMMENT INSERTED ABOVE '$str'"
	    	else
	        	echo -e "\n; $comment" >> "$ini"
	    	fi
		fi
	fi
	if [[ $startwith == "--point-coma" ]]; then
		if [[ $type == 1 ]]; then # в конец строки
			if grep -q "^$str" "$ini"; then
			   	sed -i "/^$str/ s|$| ; $comment|" "$ini"
			   	echo "INI_PARSE_DEBUG: COMMENT ADDED TO LINE '$str'"
			else
			    echo "INI_PARSE_ERROR_10: STRING '$str' NOT FOUND"
				return 1
			fi
		fi
			
		if [[ $type == 2 ]]; then # перед строкой
			if grep -q "^$str" "$ini"; then
			  	sed -i "/^$str/i ; $comment" "$ini"
			    echo "INI_PARSE_DEBUG: COMMENT INSERTED ABOVE '$str'"
			else
			    echo -e "\n; $comment" >> "$ini"
			fi

		fi
		
	fi
	
	if [[ $type == 1 ]]; then # в конец строки
			if grep -q "^$str" "$ini"; then
		   		sed -i "/^$str/ s|$| ; $comment|" "$ini"
		   		echo "INI_PARSE_DEBUG: COMMENT ADDED TO LINE '$str'"
			else
		    	echo "INI_PARSE_ERROR_10: STRING '$str' NOT FOUND"
				return 1
			fi
		fi
		
	if [[ $type == 2 ]]; then # перед строкой
		if grep -q "^$str" "$ini"; then
		        	sed -i "/^$str/i ; $comment" "$ini"
		     echo "INI_PARSE_DEBUG: COMMENT INSERTED ABOVE '$str'"
		else
		     echo -e "\n; $comment" >> "$ini"
		fi
	fi
	
	
}

# удалит комментарий
# delcom строка
delcom(){
	local str=$1
	if [[ -z $str ]]; then
		echo "INI_PARSE_ERROR_9: EMPTY STRING"
	fi
	
	if [[ ! -f "$ini" ]]; then return 1; fi

	if [[ "$str" =~ ^[#\;] ]]; then
	    sed -i "\|^$str|d" "$ini"
	    echo "INI_PARSE_DEBUG: COMMENT LINE '$str' DELETED"
	else
	     if grep -q "^$str" "$ini"; then
	         sed -i "/^$section/! { /^$str/ s/[[:space:]]*[#\;].*// }" "$ini"
	         echo "INI_PARSE_DEBUG: INLINE COMMENT REMOVED FROM '$str'"
	     else
	         echo "INI_PARSE_ERROR_10: STRING '$str' NOT FOUND"
	         return 1
	     fi
	fi
}

# главная команда
# ini аргументы
ini(){
	local flag1=$1
	local flag2=$2
	if [[ -z $flag1 && -z $flag2 ]]; then
		echo "iniparser for Unix/Linux $VERSION $BUILDING"
	fi
	if [[ -z $flag2 && ! -z $flag1 ]]; then
		case "$flag1" in
			-v|--version)
				echov
				;;
			-b|--building)
				echob
				;;
			-f|--file-name)
				if [[ -z "$ini" ]]; then 
					echo "INI_PARSE_WARNING_3: FILE ISN'T LOADED";
				else 
					echo "YOUR FILE: $ini"; 
				fi
				;;
			-i|--file-info)
				echo "data about your file $ini"
				ERRORCOUNT=0
			
				if	[[ -e "$ini" ]]; then
					echo "file is real. this is file or dir"
				else
					echo "file $ini isn't real: no such file or dir"
					(( ERRORCOUNT++ ))
				fi
			
				if [[ ! -s "$ini" ]]; then
					echo "file isn't null"
				else
					echo "file is null"
					(( ERRORCOUNT++ ))
				fi

				if [[ -f "$ini" ]]; then
					echo "this is file"
				else 
					echo "$ini isn't a file"
					(( ERRORCOUNT++ ))
				fi

				if [[ -r "$ini" ]]; then
					echo "parser can read $ini"
				else
					echo "parser can't read $ini"
					(( ERRORCOUNT++ ))
				fi

				if [[ -w "$ini" ]]; then
					echo "parser can edit $ini"
				else
					echo "parser can't edit $ini"
					(( ERRORCOUNT++ ))
				fi

				if [[ -x "$ini" ]]; then
					echo "this is file like exe, dll or sh."
					(( ERRORCOUNT++ ))
				else
					echo "this is ini"
				fi

				case $ERRORCOUNT in 
					4|5|6)
						echo "INI_PARSER_DEBUG_MESS: WERY MANY PROBLEWMS WITH FILE ($ERRORCOUNT)"
						;;
					1|2|3)
						echo "INI_PARSE_DEBUG_MESS: FIX YOUR PROBLEMS ($ERRORCOUNT)"
						;;
					0)
						echo "INI_PARSE_DEBIG_MESS: ALL OK"
						;;
				esac
				;;
			-c|--author|--copyright)
				echo "(C) ABOBIX INC."
				echo "(C) ABOBIX LINUX RESEARCH AGENCY (ALRA)"
				;;
			-h|--help-syntax-ini)
				echo "[name] - decalre section\n ; comment\n#comment to (UNIX style)\nkey=value ; key-value-pair"
				echo "example:\n [person]\n;this is a person section\name=timur\nage=11 #this is an age\nid=0"
				;;
			-var|--variables)
				echo "variables: " 
				for v in $variables; do
					echo $v
				done
				;;
			-a|--about-file-ini)
				if [[ ! -f "$ini" ]]; then
					echo "file $ini isn't exists"
				else
					ls -l -h -i "$ini"
				fi
		esac
	fi
}

createini(){
	local filename=$1
	
	if [[ -z $filename ]]; then
		echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL"
		return 1
	fi

	if [[ ! "$filename" == *".ini"* ]]; then
		filename="$filename.ini"
	fi

	touch $filename
	return 0	
}

val(){
	local name=$1
	local value=$2
	for v in $variables; do
		if [[ ! -z $variables[$name] ]]; then 
			echo "INI_PARSE_ERROR_11: VARIABLE VITH THIS NAME ALSO DECLARED"
			return 1
		else
			variables[ $name ]=$value
			return 0
		fi
	done
}

setval(){
	local name=$1
	local newval=$2
	for v in $variables; do
		if [[ -z $variables[name] ]]; then
			echo "INI_PARSE_ERROR_12: VARIABLE VITH THIS NAME ISN'T EXISTS"
			return 1
		else
			variables[ $name ]=$newval
			return 0
		fi
	done
}

delval(){
	local name=$1
	if [[ -z $variables[$name] ]]; then
		echo "INI_PARSE_ERROR_12: VARIABLE VITH THIS NAME ISN'T EXISTS"
		return 1
	else
		unset variables[ $name ]
		return 0
	fi
}


echoval(){
	local type=$1
	case $type in
		-a|--all)
			for v in $variables; do
				echo $v
			done
			;;
		-s|--selected)
			if [[ ! -z $1 && ! -z $2 ]]; then
				local name=$1
				local value=$2
				
				if [[ ! -z $variables[$name] ]]; 
				then
					echo "$name = $variables[$name]"
				fi
			fi
			;;
	esac
}

# смена названия секции
# rensec старое_имя новое_имя
rensec(){
	local old=$1 new=$2
	if [[ ! -f "$ini" ]]; then
		echo "INI_PARSE_ERROR_13: FILE NOT FOUND. CHECK WITH COMMAND 'ini --file-info' or 'ini -i' "
		return 1
	fi
	
	if [[ -z "$new"  || -z "$old" ]]; then
		echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL"
		return 1
	fi

	if ! grep -q "\[$old\]" "$ini"; then
		echo "INI_PARSE_ERROR_4: SECTION [$name] NOT FOUND"
		return 1
	fi
	sed -i "s/^\[$old\]/[$new]/" "$ini"
	return 0
}

renkey(){
	local section=$1 old=$2 new=$3
	if [[ ! -f "$ini" ]]; then
		echo "INI_PARSE_ERROR_13: FILE NOT FOUND. CHECK WITH COMMAND 'ini --file-info' or 'ini -i' "
		return 1
	fi
		
	if [[ -z "$new"  || -z "$old"  || -z "$section" ]]; then
		echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL"
		return 1
	fi
	
	if ! grep -q "\[$section\]" "$ini"; then
		echo "INI_PARSE_ERROR_4: SECTION [$name] NOT FOUND"
		return 1
	fi

	if ! grep -q "$old=" "$ini"; then
		echo "INI_PARSE_ERROR_7: KEY '$key' NOT FOUND IN SECTION '$section'"
	fi
	sed -i "/^\[$section\]/,/^\s*\[/ s/^$old=/$new=/]" "$ini"
}

rval(){
	local section=$1 key=$2 oldval=$3 newval=$4 
	 if [[ ! -f "$ini" ]]; then 
	  echo "INI_PARSE_ERROR_13: FILE NOT FOUND. CHECK WITH COMMAND 'ini --file-info' or 'ini -i' " 
	  return 1 
	 fi 
	   
	 if [[ -z "$new"  ||  -z "$old" ||  -z "$section" ]]; then 
	  echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL" 
	  return 1 
	 fi 
	  
	 if ! grep -q "\[$section\]" "$ini"; then 
	  echo "INI_PARSE_ERROR_4: SECTION [$name] NOT FOUND" 
	  return 1 
	 fi 
	 
	 if ! grep -q "$old=" "$ini"; then 
	  echo "INI_PARSE_ERROR_7 '$old' NOT FOUND IN SECTION '$section'" 
	  return 1 
	 fi 
	  sed -i "/^\[$section\]/,/^\s*\[/ s/^$key=$oldval/$key=$newval/]" "$ini" 
	 return 0 
}
pingini(){
	local type=$1 target=$2
	case type in
		-f|--file-ini-ping)
			if [[ ! -f "$ini" ]]; then
				echo "INI_PARSE_ERROR_13: FILE NOT FOUND. CHECK WITH COMMAND 'ini --file-info' OR 'ini -i'"
				return 1
			else
					echo "INI_PARSE_DEBUG_MESS: ALL OK. FILE FOUND. FOR MOR INFORMATION WRITE 'ini --file-info' OR 'ini -i'"
			fi
			;;
		-s|--section-check)
			if [[ -z "$target" ]]; then
				echo " INI_PARSE_ERROR_9: EMPTY STRING \n INI_PARSE_ERROR_0: NAME CAN'T BE NULL "
				return 1
			fi
			if ! grep -q "\[$target\]" "$ini"; then
				echo "INI_PARSE_ERROR_4: SECTION [$target] NOT FOUND"
				return 1
			else
				echo "INI_PARSE_DEBUG_MESS: SECTION EXISTS"
			fi
			;;
		-k|--key-check|-v|--value-check)
			if [[ -z "$target" ]]; then
				echo " INI_PARSE_ERROR_9: EMPTY STRING \n INI_PARSE_ERROR_0: NAME CAN'T BE NULL "
				return 1
			fi
			if ! grep -q "$target" "$ini"; then
				echo "INI_PARSE_ERROR_7: VALUE '$target' NOT FOUND IN SECTION '$section'"
				return 1
			else
				echo "INI_PARSE_DEBUG_MESS: SECTION EXISTS"
			fi
			;;
	esac
}

haskey(){
    local section=$1
    local key=$2
	if [[ ! -f "$ini" ]]; then
		echo "INI_PARSE_ERROR_13: FILE NOT FOUND. CHECK WITH COMMAND 'ini --file-info' OR 'ini -i'"
		return 1
	fi
	
	if [[ -z "$key"  || -z "$section" ]]; then
		echo "INI_PARSE_ERROR_0: NAME CAN'T BE NULL"
		return 1
	fi
		
    if sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep -q "^$key[[:space:]]*="; then
        return 0
    else
        return 1
    fi
}

loadini(){
    local section=""
    while IFS='=' read -r key value; do

        key=$(echo "$key" | xargs)

        [[ "$key" =~ ^\[(.+)\]$ ]] && {
            section="${BASH_REMATCH[1]}"
            continue
        }

        value=$(echo "$value" | xargs)

        if [[ -n "$section" && -n "$key" ]]; then
            printf -v "${section}_${key}" "%s" "$value"
        fi

    done < "$ini"
}

backupini(){
    cp "$ini" "$ini.bak.$(date +%s)"
}

ini2json(){
	awk '
		BEGIN{print "{"}
			/\[/{
    		if(sec){print "},"}
    			gsub(/[\[\]]/,"")
    			sec=$0
    			printf "\"%s\":{",sec
    			first=1
    		next
		}
		{
    	if($0~"="){
        	split($0,a,"=")
        	if(!first){printf ","}
        	printf "\"%s\":\"%s\"",a[1],a[2]
        	first=0
    	}
		}
		END{print "}}"}
		' "$ini"
}

lockini(){
    exec 200>"$ini.lock"
    flock -n 200 || {
        echo "INI file locked"
        exit 1
    }
}

validateini(){

	while read line; do

    	if [[ "$line" =~ ^\[.*$ && ! "$line" =~ \]$ ]]; then
        	echo "invalid section: $line"
	    fi

    	if [[ "$line" =~ = ]] && [[ ! "$line" =~ .+=.+ ]]; then
        	echo "invalid key-value: $line"
    	fi

	done < "$ini"
}

includeini(){
    local file=$1
    if [[ -f "$file" ]]; then
        cat "$file" >> "$ini"
    else
        echo "INI_PARSE_ERROR: INCLUDE FILE NOT FOUND"
    fi
}

keysin(){
    local section=$1
    sed -n "/^\[$section\]/,/^\s*\[/p" "$ini" | grep "=" | cut -d= -f1
}

countsections(){
	grep -c "^\[.*\]" "$ini"
}

clearcomments(){
	sed -i '/^[#;]/d' "$ini"
}

sortini(){
awk '
/\[/{
sec=$0
print sec
next
}
{
print | "sort"
}
' "$ini"
}

mergeini(){
local file=$1
cat "$file" >> "$ini"
}

tableini(){

printf "%-20s %-20s %-20s\n" "SECTION" "KEY" "VALUE"

awk -F= '

/\[/{
gsub(/\[|\]/,"")
section=$0
next
}

{
printf "%-20s %-20s %-20s\n",section,$1,$2
}

' "$ini"

}

resetini(){
> "$ini"
}

duplicates(){
grep "=" "$ini" | cut -d= -f1 | sort | uniq -d
}

exportini(){

awk -F= '
/\[/{
gsub(/\[|\]/,"")
sec=$0
next
}

{
print "export " sec "_" $1 "=" $2
}

' "$ini"

}

statsini(){

echo "sections: $(grep -c '^\[' "$ini")"
echo "keys: $(grep -c '=' "$ini")"
echo "comments: $(grep -c '^[#;]' "$ini")"

}

ini2xml(){

echo "<config>"

awk -F= '
/^\[/{
    gsub(/\[|\]/,"")
    section=$0
    print "  <"section">"
    next
}

/=/{
    gsub(/ /,"",$1)
    gsub(/^[ \t]+/,"",$2)
    print "    <"$1">"$2"</"$1">"
}

' "$ini"

awk '
/^\[/{
    gsub(/\[|\]/,"")
    print "  </"$0">"
}
' "$ini" | tac | awk '!seen[$0]++'

echo "</config>"

}

xml2ini(){

local file=$1

awk '

/<[^\/].*>/ && !/<config>/{
    gsub(/[<>]/,"")
    section=$0
    print "["section"]"
}

/<\/.*>/{
    next
}

/<.*>.*<\/.*>/{
    gsub(/<|>/,"")
    split($0,a,"/")
    split(a[1],b,">")
}

' "$file"

}


ini2yaml(){

awk -F= '

/^\[/{
    gsub(/\[|\]/,"")
    section=$0
    print section":"
    next
}

/=/{
    gsub(/ /,"",$1)
    gsub(/^[ \t]+/,"",$2)
    print "  "$1": "$2
}

' "$ini"

}

yaml2ini(){

local file=$1

yq -r '

to_entries[]
|
"[\(.key)]",
(.value | to_entries[] | "\(.key)=\(.value)")

' "$file"

}

convert(){

	case $1 in

		ini2xml)
		ini2xml
		;;

		xml2ini)
		xml2ini "$2"
		;;

		json2ini)
		json2ini "$2"
		;;

		ini2yaml)
		ini2yaml
		;;

		yaml2ini)
		yaml2ini "$2"
		;;

		esac
}

getlist(){
    local section=$1
    local key=$2

    awk -v sec="[$section]" -v k="$key" '
    BEGIN{FS="=[ ]*"; in_sec=0; found=0}

    /^\[.*\]/{
        in_sec = ($0 == sec)
        next
    }

    in_sec && $1 == k {
        print $2
        found=1
        next
    }

    in_sec && found && /^[ \t]+/ {
        gsub(/^[ \t]+/, "")
        print
        next
    }

    /^[^\t ]/ { found=0 }
    ' "$ini"
}


addtolist(){
    local section=$1
    local key=$2
    local value=$3

    if [[ -z "$section" || -z "$key" || -z "$value" ]]; then
        echo "INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL"
        return 1
    fi

    if ! grep -q "^\[$section\]" "$ini"; then
        echo -e "\n[$section]\n$key=$value" >> "$ini"
        return 0
    fi

    if haskey "$section" "$key"; then
        sed -i "/^\[$section\]/,/^\s*\[/ {
            /^\s*$key\s*=/ s|$|,$value|
        }" "$ini"
    else
        sed -i "/^\[$section\]/a $key=$value" "$ini"
    fi
}

delfromlist(){
    local section=$1
    local key=$2
    local value=$3

    sed -i "/^\[$section\]/,/^\s*\[/ {
        /^\s*$key\s*=/ {
            s/,$value//g
            s/$value,//g
            s/$value//g
        }
    }" "$ini"
}

inlist(){
    local section=$1
    local key=$2
    local value=$3

    local list=$(getlist "$section" "$key")

    for item in $(echo "$list" | tr ',' ' '); do
        if [[ "$item" == "$value" ]]; then
            return 0
        fi
    done

    return 1
}

setlist(){
    local section=$1
    local key=$2
    shift 2
    local values="$*"

    values=$(echo "$values" | tr ' ' ',')

    setkey "$section" "$key" "$values"
}

# (C) ABOBIX INC.
# (C) ABOBIX LINUX RESEARCH AGENCY (ALRA)
# INI_PARSE_ERROR_0 	INI_PARSE_ERROR_0: NAME CAN'T BE NULL
# INI_PARSE_ERROR_1 	INI_PARSE_ERROR_1: SECTION WITH THIS NAME ALREADY EXISTS ($name)
# INI_PARSE_ERROR_4     INI_PARSE_ERROR_4: SECTION [$name] NOT FOUND
# INI_PARSE_ERROR_5	    INI_PARSE_ERROR_5: KEY/VALUE CAN NOT BE NULL
# INI_PARSE_ERROR_6     INI_PARSE_ERROR_6: SECTION IS N'T EXISTS
# INI_PARSE_ERROR_7    	INI_PARSE_ERROR_7: KEY '$key' NOT FOUND IN SECTION '$section'
# INI_PARSE_ERROR_8     INI_PARSE_ERROR_8: EMPTY COMMENT
# INI_PARSE_ERROR_9     INI_PARSE_ERROR_9: EMPTY STRING
# INI_PARSE_ERROR_10    INI_PARSE_ERROR_10: STRING '$str' NOT FOUND
# INI_PARSE_ERROR_11	INI_PARSE_ERROR_11: VARIABLE VITH THIS NAME ALSO DECLARED
# INI_PARSE_ERROR_12 	INI_PARSE_ERROR_12: VARIABLE VITH THIS NAME ISN'T EXISTS
