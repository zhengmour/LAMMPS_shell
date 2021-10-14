#!/bin/bash
#处理msi2lmp.exe运行后得到的data文件
#data:2021-10-13

echo "-------------------start----------------------"
DATAFILE=$1
TMPFILE=tmp.sh
if [ ! -f $DATAFILE ]; then
	echo "This file not exist!"
else
	NEWDATAFILE=n$DATAFILE
fi

if [ ! -e $TMPFILE ]; then
	touch $TMPFILE	
fi	
echo "#/bin/bash" > $TMPFILE
chmod 755 $TMPFILE

# delete bond angle dihedral
awk '{if (NR<=3 || NR==9 || (NR>=13 && NR<=19))
		{print $0}}' $DATAFILE  > $NEWDATAFILE
line_pair=$(grep -n "Pair Coeffs" $DATAFILE | awk -F: '{print $1}')
line_atoms=$(grep -n "Atoms" $DATAFILE | awk -F: '{print $1}')
line_bonds=$(grep -n "Bonds" $DATAFILE | awk -F: '{print $1}')

echo "--------------header successfully---------------"
awk 'BEGIN{for(i=1;i<'$(($line_pair-20))';i++){num[i]=i;}} 
	{if (NR>19 && NR<'$line_pair') {
		if (!name[$2]){
			name[$2]=$1;
			print "echo " "\"" $0 "\" " " >> '$NEWDATAFILE'" '\n';
		} else {		
			num[$1]=name[$2];
		};
	}}
	END{{for (x in num) print "change_num["x"]=" num[x] '\n'}
	{len=length(name)-1;
	str="   "len" atom types";
	print "sed -i '\''4c "str"'\'' '$NEWDATAFILE'" '\n'}}' $DATAFILE >> $TMPFILE

echo "------------create a mapping table-------------"
# delete 2,8,9,10 of atoms
awk '{if (NR>'$(($line_atoms-1))' && NR<'$(($line_bonds-1))'){
	if($1=="Atoms"){
	print "echo \"Atoms # charge\" >> '$NEWDATAFILE'" '\n';
	} else if ($3!=""){
        print "echo \""$1"\""" ${change_num["$3"]} ""\" "$4" "$5" "$6" "$7"\" >> '$NEWDATAFILE'"'\n';
        }else {
	print "echo \" \" >> '$NEWDATAFILE'" '\n'; 
	}}}' $DATAFILE >> $TMPFILE

source ./$TMPFILE

echo "--------------successfully end-----------------"
rm ./$TMPFILE
unset line_pair
unset line_atoms
unset line_bonds
unset change_num

echo "------------solve some question----------------"
# In the Masses, the serial number is not continuous
line_masses=$(grep -n "Masses" $NEWDATAFILE | awk -F: '{print $1}')
line_atoms=$(grep -n "Atoms" $NEWDATAFILE | awk -F: '{print $1}')

# create a new mapping table
eval $(awk -v mass="$(($line_masses+1))" -v atom="$(($line_atoms-1))" 'BEGIN{count=1}
	{if (NR>mass && NR<atom){
		print "num["$1"]="count;
		count++;	
	}}' $NEWDATAFILE)

str=""
bool=1
for key in ${!num[@]}
do
	echo $key ${num[$key]}
	str=$str"$key#"
	if [ ${num[$key]} != $key ];then
		bool=0
	fi
done

if [ $bool == 1 ];then	
	echo "--------------------finally-----------------"
	exit 10
fi

echo "--------------write new new file-------------"
if [ -f $NEWDATAFILE ]; then
        NEWDATAFILE2=nn$DATAFILE
fi

awk -v mass="$(($line_masses+1))" -v atom="$(($line_atoms-1))" -v str="$str" 'BEGIN{
	split(str,a,"#");for (i in a){num[a[i]]=i};}
	{if(NR<=mass){
		print $0		
	}else if(NR>mass && NR<atom){
		print "   "num[$1]" "$2	
	}else if(NR>=atom && NR<atom+3){
		print $0	
	}else {
		print $1" "num[$2]" "$3"  "$4" "$5" "$6
	}}' $NEWDATAFILE > $NEWDATAFILE2

echo "----------------finally----------------------"
unset line_atoms
unset line_masses
unset str
unset num













