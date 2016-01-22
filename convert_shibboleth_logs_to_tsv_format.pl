#!/usr/bin/perl
#
# convert_shibboleth_logs_to_tsv_format.pl
# This script converts Shibboleth idp-process.log log files into
# a tab separated format.  
#
# Usage:  ./convert_shibboleth_logs_to_tsv_format.pl file1 file2 ...
#
# Run these commands to setup the geolocation software
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
#
# This script does not do geolocation, although it looks like it should.
# I actually do the geolcation in analyze_shibboleth_logs.pl
#
# But I have the code here in case somebody decides it should be done here.
#

sub geo_locate_country{
	$ip=shift;
	my $tmp;
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
		#print "$tmp\n";
		return ($tmp);
	}
	return ("undefined");

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


sub read_file {
	
	my $file=shift;
	chomp $file;
	print (STDERR "Looking at $file now\n");
	if ($file =~ /.gz/){
		open (FILE, "zcat $file|") || die "Can not open $file for reading\n";
	}
	else {
		open (FILE, $file) || die "Can not open $file for reading\n";
	}
	
	while (<FILE>){
		chomp;
		if (/Successfully authenticated/){
			($date,$time,$trash,$trash,$trash,$trash,$ip,$trash,$trash,$trash,$trash,$name)=split (/ /,$_);
			print "$ip\tValidLogin\t$date $time\t$name\n";
		}
		if (/User authentication for.* failed/){
			($date,$time,$trash,$trash,$trash,$trash,$ip,$trash,$trash,$trash,$trash,$name)=split (/ /,$_);
			print "$ip\tFailedLogin\t$date $time\t$name\n";
		}
	
	}
}

while ($filename=shift) {$files="$files $filename";}

use Geo::IP;
$new_record=0;
$record="";
$print_record=0;


open (LS, "/bin/ls $files |") || die "Can not run ls command, exiting now\n";
while (<LS>){
	&read_file ("$_");
}
close (LS);
