#!/bin/bash
cd ${WORKSPACE_LOC}
RS_ARRAY=($(ls *perf_result_set.txt))
echo " <html>"  >  ${WORKSPACE}/multibench_perf_result.html 
echo "   <head>"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "     <script type="text/javascript""  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "           src=\"https://www.google.com/jsapi?autoload={"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "             'modules':[{"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "               'name':'visualization',"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "               'version':'1',"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "               'packages':['corechart']"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "             }]"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "           }\"></script>"  >>  ${WORKSPACE}/multibench_perf_result.html 

i=0
for file in "${RS_ARRAY[@]}"; do
  count=$((i++));
  BENCH_TYPE=`echo $file | cut -d _ -f 1`
  BENCHMARCK=`echo $file | cut -d _ -f 2`
  if [ $BENCH_TYPE == "iibench" ]; then
    echo "     <script type=\"text/javascript\">"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "       google.load(\"visualization\", \"1\", {packages:[\"corechart\"]});" >>${WORKSPACE}/multibench_perf_result.html
    echo "       google.setOnLoadCallback(drawChart$count);"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "       function drawChart$count() {"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "         var data = google.visualization.arrayToDataTable(["  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "           ['Build',  '20M' , '40M' , '60M ' , '80M' , '100M' , 'Avg IPS' ]," >> ${WORKSPACE}/multibench_perf_result.html
  else
    echo "     <script type=\"text/javascript\">"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "       google.setOnLoadCallback(drawChart$count);"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "       function drawChart$count() {"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "         var data = google.visualization.arrayToDataTable(["  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "           ['Build', 'Thread_1' , 'Thread_4' , 'Thread_16' , 'Thread_64' , 'Thread_128' , 'Thread_256' , 'Thread_512' , 'Thread_1024']," >> ${WORKSPACE}/multibench_perf_result.html 
    #echo "           ['Build', 'Thread_1' , 'Thread_4' ]," >> ${WORKSPACE}/multibench_perf_result.html
  fi
  tail -10 $file  >>  ${WORKSPACE}/multibench_perf_result.html 
  echo "         ]);"  >>  ${WORKSPACE}/multibench_perf_result.html 
  echo "         var options = {"  >>  ${WORKSPACE}/multibench_perf_result.html
  if [ $BENCH_TYPE == "fbpileup" ]; then
    FBPILEUP_TYPE=`echo $file | cut -d _ -f 2`
    echo "           title: '$BENCH_TYPE $FBPILEUP_TYPE performance result',"  >>  ${WORKSPACE}/multibench_perf_result.html
  else
    echo "           title: '$BENCH_TYPE ${BENCHMARCK} performance result',"  >>  ${WORKSPACE}/multibench_perf_result.html 
  fi
  echo "           hAxis: {title: \"BUILD\"},"  >>  ${WORKSPACE}/multibench_perf_result.html
  
  if [ $BENCH_TYPE == "iibench" ]; then
    echo "           vAxis: {title: \"IPS\"},"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "           seriesType: \"bars\","  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "           series: {5: {type: \"line\"}}"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "         };"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "         var chart = new google.visualization.ComboChart(document.getElementById('curve_chart$count'));"  >>  ${WORKSPACE}/multibench_perf_result.html
  else
    echo "           vAxis: {title: \"AVG QPS\"},"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "           curveType: 'function'"  >>  ${WORKSPACE}/multibench_perf_result.html 
    echo "         };"  >>  ${WORKSPACE}/multibench_perf_result.html
    echo "         var chart = new google.visualization.LineChart(document.getElementById('curve_chart$count'));"  >>  ${WORKSPACE}/multibench_perf_result.html
  fi
 
  echo "         chart.draw(data, options);"  >>  ${WORKSPACE}/multibench_perf_result.html 
  echo "       }"  >>  ${WORKSPACE}/multibench_perf_result.html
  echo "     </script>"  >>  ${WORKSPACE}/multibench_perf_result.html 
done
echo "   </head>"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo "   <body>"  >>  ${WORKSPACE}/multibench_perf_result.html
echo "   <table>" >>  ${WORKSPACE}/multibench_perf_result.html
echo "   <tr>" >>  ${WORKSPACE}/multibench_perf_result.html
cat $WORKSPACE/hw.info >> ${WORKSPACE}/multibench_perf_result.html
tail -10 $WORKSPACE/build_info.log | xargs -IX printf '<br>%s\n' X >> ${WORKSPACE}/multibench_perf_result.html
echo "   </tr>" >>  ${WORKSPACE}/multibench_perf_result.html
i=0
for file in "${RS_ARRAY[@]}"; do 
  count=$((i++));
  [ $((count%2)) -eq 0 ] && echo "<tr>"  >>  ${WORKSPACE}/multibench_perf_result.html
  echo "<td>     <div id=\"curve_chart$count\" style=\"width: 700px; height: 500px\"></div></td>"  >>  ${WORKSPACE}/multibench_perf_result.html 
  [ $((count%2)) -ne 0 ] && echo "</tr>"  >>  ${WORKSPACE}/multibench_perf_result.html
done
[ $((count%2)) -eq 0 ] && echo "</tr>"  >>  ${WORKSPACE}/multibench_perf_result.html
echo "   </table>" >>  ${WORKSPACE}/multibench_perf_result.html
echo "   </body>"  >>  ${WORKSPACE}/multibench_perf_result.html 
echo " </html>"  >>  ${WORKSPACE}/multibench_perf_result.html 

