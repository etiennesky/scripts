#!/usr/bin/perl

require "/data/docs/research/scripts/get_modis_func.pl";

#  ftp://e4ftl01.cr.usgs.gov/MOLT/MOD09GA.005/2000.04.19/

my $ftp_site     = 'e4ftl01.cr.usgs.gov';
my $ftp_dir      = '/MOLT/MOD13Q1.005/';
my $ftp_user     = 'anonymous';
my $ftp_password = 'user@example.com';

my @ftp_config = ($ftp_site,$ftp_dir,$ftp_user,$ftp_password);
my @years = (2011);
#my @months = (1 .. 12);
my @months = (1 .. 3);
#my @months = (6);
#my @days = (1 .. 31);
my @days = (1 .. 31);


#my $indexes_hv = "h10v08|h11v08|h12v08|h10v09|h11v09|h12v09|h13v09|h14v09|h10v10|h11v10|h12v10|h13v10|h14v10|h11v11|h12v11|h13v11|h14v11|h11v12|h12v12|h13v12|h12v13|h13v13|h13v14|h14v14";
##my $indexes_hv = "h10v08|h11v08|h12v08|h10v09|h11v09|h12v09|h13v09|h14v09|h10v10|h11v10|h12v10|h13v10|h14v10|h11v11|h12v11|h13v11|h14v11|h11v12|h12v12|h13v12|h12v13|h13v13|h13v14|h14v14|h13v08|h09v09|h10v07|h11v07|h09v08";
my $indexes_hv = "*";
my $indexes_hv = "h13v08|h09v08|h09v09";

#print "years: " . "@years\n";
#print "months: " . "@months\n";
#print "days: " . "@days\n";

#my $suffixes = "jpg";
my $suffixes = "jpg|hdf|hdf.xml";
#my $suffixes = "hdf";
my $prefixes = "BROWSE.MOD13A1.";
		
get_modis(\@ftp_config,\@years,\@months,\@days,$indexes_hv,$suffixes,$prefixes,"mod13q1-test");
