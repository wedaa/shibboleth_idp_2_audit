#!/usr/bin/perl
#######################################################################
# Written by Eric.Wedaa@marist.edu
# Date: 2016/01/22
#
# This is for Shibboleth 2.X IDP 
#
# Usage: ./analyze_shibboleth_tsv_files.pl filename
# Usage: /usr/local/etc/analyze_shibboleth_tsv_files.pl filename
#
# Input format is tab separated fields from 
# /usr/local/etc/convert_shibboleth_logs_to_tsv_format.pl
#
#######################################################################
#Sample input file looks like this:
#10.6.16.108	FailedLogin	2016-01-22 10:23:21.434	urew
#10.6.16.108	ValidLogin	2016-01-22 10:25:13.821	urew
#10.6.16.108	ValidLogin	2016-01-22 11:05:09.976	urew
#10.6.16.108	FailedLogin	2016-01-22 11:15:21.434	Xrew
# 
#######################################################################
# Edit $local_ip_1 and $local_ip_2 for your local networks
#
#######################################################################
# Shibboleth logging.xml file needs the following lines
#     <!--Added by ericw eric wedaa at Marist.edu, logs authentication events-->
#     <logger name="edu.internet2.middleware.shibboleth.idp.authn" level="DEBUG"/>
#AND
# <Pattern>%date{yyyy-MM-dd HH:mm:ss.SSS} - %level [%logger:%line] - %mdc{clientIP} - %msg%n</Pattern>
# 
# Please see sample included logging.xml file for the precise locations
#######################################################################
#
# Do the following commands to setup for geolocation
#
#yum install cpan
#cpan CPAN
#cpan Geo::IP
#cpan Socket6
#mkdir /usr/local/share/GeoIP
#mkdir /usr/local/share/GeoIP/backups # Will be used to store older copies of database files
#cd /usr/local/share/GeoIP
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
#wget geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
#wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
#gunzip GeoIP.dat.gz
#gunzip GeoLiteCity.dat.gz
#gunzip GeoIPv6.dat.gz
#######################################################################
#
# Please note that there is commented out code for geolocating the city
# It is commented out since the free database is not as precise as I
# would like, so I don't use it.  Feel free to modify this code yourself.
#
#######################################################################


sub geolocate_ip{
	$ip=shift;
#print (STDERR "In geolocate for $ip\n");
	my $tmp;
	if ($ip =~ /^$local_ip_1/){return ("US-Marist");}
	if ($ip =~ /^$local_ip_2/){return ("US-Marist");}
#print (STDERR "Foo\n");
  my $gi = Geo::IP->open("/usr/local/share/GeoIP/GeoLiteCity.dat", GEOIP_STANDARD);
  my $record = $gi->record_by_addr($ip);
  #print $record->country_code,
  #      $record->country_code3,
  #      $record->country_name,
  #      $record->region,
  #      $record->region_name,
  #      $record->city,
  #      $record->postal_code,
  #      $record->latitude,
  #      $record->longitude,
  #      $record->time_zone,
  #      $record->area_code,
  #      $record->continent_code,
  #      $record->metro_code;
	# ericw note: I have no idea what happens if there IS a record
	# but there is no country code
	undef ($tmp);
	if (defined $record){
		$tmp=$record->country_code;
		return "$tmp";
	}
	else {
		return ("undefined");
	}

  # the IPv6 support is currently only avail if you use the CAPI which is much
  # faster anyway. ie: print Geo::IP->api equals to 'CAPI'
  #use Socket;
  #use Socket6;
  #use Geo::IP;
  #my $g = Geo::IP->open('/usr/local/share/GeoIP/GeoIPv6.dat') or die;
  #my $g = Geo::IP->open('GeoLiteCity.dat') or die;
  #print $g->country_code_by_ipnum_v6(inet_pton AF_INET6, '::24.24.24.24');
  #print $g->country_code_by_addr_v6('2a02:e88::');
}
#####################################################################
#
# Mainline of code
#
use Geo::IP;
$file=shift;
#print "file is $file\n";
$local_ip_1="148.100";
$local_ip_2="10.";

if ($file =~ /.gz/){
	open (INPUT, "zcat $file|") || die "can not read $file\n";
}
else {
	open (INPUT, "$file") || die "can not read $file\n";
}
$prior_username="";
$prior_ip="";
$prior_login="";
$prior_countries="";
$prior_countries_count=0;
$failed_login_count=0;
$number_of_ips=0;
$interesting_failed_ips=1;
$interesting_failed_logins=1;
$local_ip_1="10.";
$local_ip_2="148.100";
print "number_of_ips,number_of_countries,countries,'prior_username',failed_login_count,ip_string\n";

while (<INPUT>){
	chomp;
	if ( /FailedLogin/){
		($ip,$login,$date,$username)=split(/\t/,$_,4);
		if ($username ne $prior_username){
			if ($prior_username ne ""){
					$prior_username =~ s/'/\\'/g;
					$usernames_countries{$prior_username}="$usernames_countries{$prior_username}".":$countries";
					$usernames_ips{$prior_username}="$usernames_ips{$prior_username}".":$ip_string";
					$usernames_count{$prior_username}+=$failed_login_count;
					$usernames{$prior_username}=$prior_username;
					print "$number_of_ips,$number_of_countries,$countries,'$prior_username',$failed_login_count,$ip_string\n";
					$prior_username=$username;
					$prior_ip=$ip;
					$ip_string=$ip;
					$failed_login_count=1;
					$number_of_ips=1;
					$countries=&geolocate_ip($ip);
					#print (STDERR "countries is $countries\n");
					$number_of_countries=1;
			}
			else { # Prior username is blank!
				#print (STDERR "prior username is blank\n");
				$prior_ip=$ip;
				$ip_string=$ip;
				$failed_login_count=1;
				$prior_username=$username;
				$failed_login_count=1;
				$number_of_ips=1;
				$new_country=&geolocate_ip($ip);
				$countries=&geolocate_ip($ip);
				#print (STDERR "Blank prior new_countries is $new_country\n");
				$number_of_countries=1;
			}
		}
		else {  # username matches prior_username
			if ($prior_ip ne $ip){ 
				$new_country=&geolocate_ip($ip);
				#print (STDERR "new_countries is $new_country\n");
				$ip_string="$ip_string:$ip";
				$number_of_ips++; 
				$prior_ip=$ip;
				$number_of_countries++;
				$countries="$countries:$new_country"
			}
			$failed_login_count++;
		}
	}
}
close (INPUT);
# Gotta print the last entry cause it won't be in the loop anymore
if ( ( $number_of_ips >= $interesting_failed_ips) || ( $failed_login_count >= $interesting_failed_logins) ) {
	$usernames{$prior_username}=$prior_username;
	$usernames_countries{$prior_username}="$usernames_countries{$prior_username}".":$countries";
	$usernames_ips{$prior_username}="$usernames_ips{$prior_username}".":$ip_string";
	$usernames_count{$prior_username}+=$failed_login_count;
	print "LAST $number_of_ips,$number_of_countries,$countries,$prior_username,$failed_login_count,$ip_string\n";
}
print "\n\n\n\n";
foreach $username (keys %usernames){
	print "TOTAL INVALID LOGINS FOR,$username,$usernames_count{$username},$usernames_countries{$username},$usernames_ips{$username}\n";
}
print "\n\n\n\n";
#####################################################################
#
# Analyze all valid logins looking for multiple countries or non-US countries


if ($file =~ /.gz/){
	open (INPUT, "zcat $file|") || die "can not read $file\n";
}
else {
	open (INPUT, "$file") || die "can not read $file\n";
}
$prior_username="";
$prior_ip="";
$prior_login="";
$prior_countries="";
$prior_countries_count=0;
$failed_login_count=0;
$number_of_ips=0;
$interesting_failed_ips=2;
$interesting_failed_logins=5;
$local_ip_1="10.";
$local_ip_2="148.100";

while (<INPUT>){
	chomp;
	if ( /ValidLogin/){
		($ip,$login,$date,$username)=split(/\t/,$_,4);
		if ($username ne $prior_username){
			if ($prior_username ne ""){
				$prior_username =~ s/'/\\'/g;
				$valid_username{$prior_username}=$prior_username;
				$valid_usernames_countries{$prior_username}="$valid_usernames_countries{$prior_username}".":$countries";
				$valid_usernames_ips{$prior_username}="$valid_usernames_ips{$prior_username}".":$ip_string";
				$valid_usernames_count{$prior_username}+=$failed_login_count;
				$valid_usernames{$prior_username}=$prior_username;
				#print "$number_of_ips,$number_of_countries,$countries,'$prior_username',$failed_login_count,$ip_string\n";
				$prior_username=$username;
				$prior_ip=$ip;
				$ip_string=$ip;
				$failed_login_count=1;
				$number_of_ips=1;
				$countries=&geolocate_ip($ip);
				$number_of_countries=1;
			}
			else { # Prior username is blank!
				$prior_ip=$ip;
				$failed_login_count=1;
				$prior_username=$username;
				$failed_login_count=1;
				$number_of_ips=1;
				$new_country=&geolocate_ip($ip);
				$number_of_countries=1;
			}
		}
		else {  # username matches prior_username
			if ($prior_ip ne $ip){ $new_country=&geolocate_ip($ip);$ip_string="$ip_string:$ip";$number_of_ips++; $prior_ip=$ip;$number_of_countries++;$countries="$countries:$new_country"}
			$failed_login_count++;
		}
	}
}
close (INPUT);
# Gotta print the last entry cause it won't be in the loop anymore
$valid_usernames{$prior_username}=$prior_username;
$valid_usernames_countries{$prior_username}="$usernames_countries{$prior_username}".":$countries";
$valid_usernames_ips{$prior_username}="$usernames_ips{$prior_username}".":$ip_string";
$valid_usernames_count{$prior_username}+=$failed_login_count;
foreach $username (keys %valid_usernames){
	#print "VALID LOGIN TOTAL FOR,$username,$valid_usernames_count{$username},$valid_usernames_countries{$username},$valid_usernames_ips{$username}\n";
	$tmp=$valid_usernames_countries{$username};
	$number_of_countries=`echo $tmp |sed 's/:/\\n/g' |sort |uniq |wc -l`;
	chomp $number_of_countries;
	$number_of_countries--;

	print "VALID LOGIN TOTAL FOR,$username,$valid_usernames_count{$username},$number_of_countries,$valid_usernames_countries{$username}\n";
}
