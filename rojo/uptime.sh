#!/bin/bash
HOME=/home/rojo/Cumplo/status
FECHA_HORA=`date +%Y-%m-%d_%H:%M:%S`
FECHA=`date +%Y-%m-%d`
HORA=`date +%H:%M:%S`
contCumplo=`cat $HOME/contadorCumplo.cnt`
incremento=1

#
#### Verificar estado de Cumplo ####
#
wget --delete-after --timeout=25 --tries=3 --output-file=$HOME/temp.txt --no-check-certificate --wait=5 --retry-connrefused https://www.cumplo.cl
if [ $? -ne 0 ]; then
        if [ "$contCumplo" -ne 3 ]; then
                cat $HOME/temp.txt | mail -s "Cumplo is Down - RUN IN CIRCLES!" fernando@cumplo.com
                curl -d 'message=Home@Cumplo Down D:' http://im.kayac.com/api/post/rojo &> /dev/null
		contCumplo=$((contCumplo+incremento))
                echo $contCumplo > $HOME/contadorCumplo.cnt
                echo "Down;$HORA" >> $HOME/logs/$FECHA.log
        fi
else
        if [ "$contCumplo" -gt 0  ]; then
                echo "$FECHA_HORA Cumplo is alive!" | mail -s "Cumplo is Up - Relax" fernando@cumplo.com
		curl -d 'message=Home@Cumplo Up :D' http://im.kayac.com/api/post/rojo &> /dev/null
                echo "Up;$HORA" >> $HOME/logs/$FECHA.log
        fi
        echo "0" > $HOME/contadorCumplo.cnt
fi
rm $HOME/temp.txt

