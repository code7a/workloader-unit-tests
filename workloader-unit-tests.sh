#remove previous bin
rm -rf ./linux_amd64-v*

#wget latest workloader release
wget $(curl -s https://api.github.com/repos/brian1917/workloader/releases/latest | jq -r '.assets[] | select(.name | startswith("linux_amd64")) | .browser_download_url');

#unzip
unzip ./linux_amd64-v*;

#workload import
echo 'hostname,name,managed,role,app,env,loc,interfaces
wkld_import.local,wkld_import.local,false,r-import,a-jenkins,e-prod,e-default,ens192:10.1.1.1/16' > wkld_import.csv;
./linux_amd64-v*/workloader wkld-import wkld_import.csv --umwl --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#workload export
./linux_amd64-v*/workloader wkld-export;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#workload delete
./linux_amd64-v*/workloader delete $(cat workloader-wkld-export-*.csv | grep wkld_import.local | cut -d ',' -f 10) --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ven export
./linux_amd64-v*/workloader ven-export;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ven update
#update the last ven's description with the date
sed 's/'"$(cat workloader-ven-export-*.csv | grep $(cat workloader-ven-export-*.csv | tail -1 | cut -d ',' -f 1) | cut -d ',' -f 3)"'/'"$(date)"'/g' workloader-ven-export-*.csv > workloader-ven-import.csv;
./linux_amd64-v*/workloader ven-import workloader-ven-import.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ven update
#revert the last ven's description to the initial export
./linux_amd64-v*/workloader ven-import workloader-ven-export-*.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ipl import
echo 'name,description,include,exclude,fqdns,external_data_set,external_data_ref,href
cloudflare_test,,1.1.1.1,,,,,' > workloader-ipl-import.csv;
./linux_amd64-v*/workloader ipl-import workloader-ipl-import.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ipl replace
echo 'ip,description
1.1.1.1,dns 1
1.1.1.2,dns 2' > workloader-ipl-replace.csv;
./linux_amd64-v*/workloader ipl-replace cloudflare_test -i workloader-ipl-replace.csv --ip-desc-col 2 --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ipl export
./linux_amd64-v*/workloader ipl-export;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#ipl delete
./linux_amd64-v*/workloader delete $(cat workloader-ipl-export-*.csv | grep cloudflare_test | cut -d ',' -f 8) --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#label import
echo 'key,value
app,app_1
app,app_2
app,app_3' > workloader-label-import.csv;
./linux_amd64-v*/workloader label-import workloader-label-import.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#label export
./linux_amd64-v*/workloader label-export;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#label update
sed -i 's/app_1/app_4/g' workloader-label-export-*.csv;
./linux_amd64-v*/workloader label-import workloader-label-export-*.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#labelgroup import
echo 'name,key,member_labels
app_group,app,app_2;app_3' > workloader-labelgroup-import.csv;
./linux_amd64-v*/workloader labelgroup-import workloader-labelgroup-import.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#labelgroup export
./linux_amd64-v*/workloader labelgroup-export;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#labelgroup update
sed -i 's/app_3/app_4/g' workloader-label-group-export-*.csv;
./linux_amd64-v*/workloader labelgroup-import workloader-label-group-export-*.csv --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#labelgroup export
rm -f workloader-label-group-export-*.csv
./linux_amd64-v*/workloader labelgroup-export;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#labelgroup delete
./linux_amd64-v*/workloader delete $(cat workloader-label-group-export-*.csv | grep app_group | cut -d ',' -f 7) --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#label delete
./linux_amd64-v*/workloader delete $(cat workloader-label-export-*.csv | grep app_2 | cut -d ',' -f 1) --update-pce --no-prompt;
./linux_amd64-v*/workloader delete $(cat workloader-label-export-*.csv | grep app_3 | cut -d ',' -f 1) --update-pce --no-prompt;
./linux_amd64-v*/workloader delete $(cat workloader-label-export-*.csv | grep app_4 | cut -d ',' -f 1) --update-pce --no-prompt;
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

#clean up unused app labels
rm -f workloader-label-export-*.csv
./linux_amd64-v*/workloader label-export;
#grep labels, type app, no used
label_hrefs=($(cat workloader-label-export-*.csv | grep ',app,' | grep -v true | cut -d ',' -f 1))
for label_href in "${label_hrefs[@]}"; do
    ./linux_amd64-v*/workloader delete $label_href --update-pce --no-prompt;
done
cat workloader.log | grep ERROR | grep -v "http status code of 500" && exit 1;

exit 0;
