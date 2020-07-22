#!/bin/sh

dbname=$1		# the name of db
dbpath=$2		# the path to db on host
ext=fbk			# backup db extension

current_date=$(date +%F)	# current date

do_date=$3
do_bzip=$4

length=10
days=6

bzip_ext=''

mail_if_failure()
{
    if [ $? != "0" ]
    then
	echo "Can't backup!" | mail -s "$(hostname): $dbname error!" yourname@your.ru
	exit 1
    fi
}
mail_if_ok()
{
    if [ $? != "0" ]
    then
        echo "Backup ok " | mail -s "$(hostname): $dbname success!"  yourname@your.ru
    exit 1
    fi
}
			    
do_backup()
{
    if [ -z "$1" ]
    then
	exit 1
    else
	#############################################
	# DBMS-related code: 			
	# >>>> ONLY HERE!!!!!!! <<<<
	nice -n 15 /usr/local/firebird/bin/gbak -B -T $dbpath/$dbname $1
	#############################################
	if [ $? != "0" ]
	then
	    mail_if_failure
	fi

    fi
}

rotate_dbs()
{
    # Если уже есть один файл, то надо делать ротацию
    if [ -f $dbpath/backup/$dbname.$ext$bzip_ext ]
    then
	i=$(($length-1))
	# Цикл, осуществляющий смещение
	while [ "$i" -gt 0 ] 
	do
	    j=$(($i+1))
	    # Смещаем
	    if [ -f $dbpath/backup/$dbname.$ext.$i$bzip_ext ]
	    then
		mv $dbpath/backup/$dbname.$ext.$i$bzip_ext $dbpath/backup/$dbname.$ext.$j$bzip_ext
	    fi
	    let "i -= 1"
	done
	mv $dbpath/backup/$dbname.$ext$bzip_ext $dbpath/backup/$dbname.$ext.1$bzip_ext
    fi
}

rotate_dbs_timestamp()
{
    # Получаем список файлов, удовлетворяющих маске $dbname.$ext.????-??-??,
    # дата создания которых - больше чем $days дней назад.
    remove_list=$(find $dbpath/backup -mtime +$days -iname $dbname.$ext.????-??-??$bzip_ext)
    # И если полученный список не пуст - удаляем их
    if [ ! -z "$remove_list" ]
    then
	rm $remove_list
    fi
}

#########################################################
#
# 	BoDY oF BuDDha SCriPt
#
#########################################################

# Смотрим, следует нам работать с файлами .bz2 или же с не сжатыми, в зависимости от этого и 
# устанавливаем переменную $bzip_ext
if [ x$do_bzip == "xyes" ]
then
    bzip_ext='.bz2'
fi

if [ x$do_date == "xyes" ]
then
    if [ x$do_bzip == "xyes" ]
    then
	abkname=$dbpath/backup/$dbname.$ext.$current_date
	mbkname=${abkname}'.bz2'
    else
	mbkname=$dbpath/backup/$dbname.$ext.$current_date
    fi

    if [ ! -f $mbkname ]
    then
	rotate_dbs_timestamp
	do_backup $dbpath/backup/$dbname.$ext.$current_date
	if [ x$do_bzip == "xyes" ]
	then
	    nice -n 15 bzip2 $dbpath/backup/$dbname.$ext.$current_date
	fi
    else
	rotate_dbs
	do_backup $dbpath/backup/$dbname.$ext
	if [ x$do_bzip == "xyes" ]
	then
	    nice -n 15 bzip2 $dbpath/backup/$dbname.$ext
	fi
    fi
else
    rotate_dbs
    do_backup $dbpath/backup/$dbname.$ext
    if [ x$do_bzip == "xyes" ]
    then
	nice -n 15 bzip2 $dbpath/backup/$dbname.$ext
    fi
fi
