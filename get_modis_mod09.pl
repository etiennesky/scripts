#!/usr/bin/perl

require "/data/docs/research/scripts/get_modis_func.pl";

#  ftp://e4ftl01.cr.usgs.gov/MOLT/MOD09GA.005/2000.04.19/

my $ftp_site     = 'e4ftl01.cr.usgs.gov';
#my $ftp_dir      = '/MOLT/MOD09GA.005';
#my $ftp_dir      = '/MOLA/MYD09GQ.005';
my $ftp_dir      = '/WORKING/BRWS/Browse.001';
#my $ftp_dir      = '/WORKING/BRWS';
#my $ftp_dir      = '/';
my $ftp_user     = 'anonymous';
my $ftp_password = 'user@example.com';

#$ftp_site     = 'localhost';
#$ftp_dir      = '/data/tmp/modis/MOLT/MCD45A1';
#$ftp_user     = 'test';
#$ftp_password = 'testpass';

my @ftp_config = ($ftp_site,$ftp_dir,$ftp_user,$ftp_password);
#@years = (2003 .. 2010);
#@months = (01 .. 12);
#@days = (01 .. 31);
#my @years = (2010 .. 2011);
#my @months = (6 .. 7);
#my @days = (1 .. 31);
my @years = (2010);
my @months = (10);
my @days = (5);


#my @indexes_hv = ("h13v09","h13v10","h13v11","h12v10","h12v11");
#$indexes2_hv = "{h13v09,h13v10,h13v11,h12v10,h12v11}";
#my $indexes2_hv = "{h13v09,h13v10}";
#$indexes3_hv = "h13v09|h13v10|h13v11|h12v10|h12v11";
#my $indexes_hv = "h13v10|h12v10|h12v09|h11v09";
my $indexes_hv = "h13v10|h12v10|h13v09|h12v09|h11v09";
#my $indexes_hv = "h13v09";

#print "years: " . "@years\n";
#print "months: " . "@months\n";
#print "days: " . "@days\n";

my $suffixes = ".jpg";
#my $suffixes = "jpg|hdf|hdf.xml";
my $prefixes = "BROWSE.MOD09GA.";

get_modis(\@ftp_config,\@years,\@months,\@days,$indexes_hv,$suffixes,$prefixes,"tmp2");
