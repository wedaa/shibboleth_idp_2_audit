#!/bin/sh
echo "Installing geolocation software and files now"
yum install cpan
cpan CPAN
cpan Geo::IP
cpan Socket6
mkdir /usr/local/share/GeoIP
mkdir /usr/local/share/GeoIP/backups # Will be used to store older copies of database files
cd /usr/local/share/GeoIP
wget geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
wget geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
gunzip GeoIP.dat.gz
gunzip GeoLiteCity.dat.gz
gunzip GeoIPv6.dat.gz

