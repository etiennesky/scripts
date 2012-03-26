#!/usr/bin/perl

require "/data/docs/research/bin/get_modis_func.pl";

#  ftp://e4ftl01.cr.usgs.gov/MOLT/MOD09GA.005/2000.04.19/

my $ftp_site     = 'e4ftl01.cr.usgs.gov';
my $ftp_dir      = '/MOTA/MCD45A1.005';
#my $ftp_dir      = '/MOLA/MYD09GQ.005';
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
##my @years = (2000 .. 2009);
my @years = (2011);
my @months = (1 .. 12);
#my @months = (6);
my @days = (1);


#north amazon
#my $indexes_hv = "h12v09|h11v09|h11v10";

#missing BR
#my $indexes_hv = "h11v08|h12v08|h14v09|h14v10|h13v12";
#missing amz
#my $indexes_hv = "h11v08|h12v08";
#missing SA
my $indexes_hv = "h12v08|h11v08";
#my $indexes_hv = "h13v09|h13v10|h13v11|h12v09|h12v10|h12v11";
#my $indexes_hv = "h11v08|h12v08|h14v09|h14v10|h13v12|h10v08|h12v12|h12v13|h13v13";

#print "years: " . "@years\n";
#print "months: " . "@months\n";
#print "days: " . "@days\n";

#my $suffixes = "jpg";
my $suffixes = "jpg|hdf|hdf.xml";



get_modis(\@ftp_config,\@years,\@months,\@days,$indexes_hv,$suffixes,"mcd45-2011-3");
