## #!/usr/bin/perl
use strict;
use warnings;
#use Net::FTP;
use Cwd;
use Cwd 'chdir';
  


sub gdal_extract_hdf {
my ($ifile) = @_

    print "gdal_extract_hdf $ifile \n";
}

gdal_extract_hdf("MOD09GA.A2010190.h12v09.005.2010192101826.hdf");


get_modis1 {

    print "#func get_modis()\n";
#    print @_;
#    die "bla";

    my @remote_files;
    my @filtered_files1;
    my @filtered_files2;
    my $tmp_file2 = "";
    my $tmp_size = 0;
    my $tmp_size2 = 0;
    my $tmp_size3 = 0;
#    my (@ftp_config, @years,@months,@days,$indexes_hv) = @_;
    my ($ftp_config, $_years,$_months,$_days,$indexes_hv,$suffixes,$ofile_prefix) = @_;
    my @years=@{$_years};
    my @months=@{$_months};
    my @days=@{$_days};

    my $ftp_site = @{$ftp_config}[0];
    my $ftp_dir = @{$ftp_config}[1];
    my $ftp_user = @{$ftp_config}[2];
    my $ftp_password = @{$ftp_config}[3];

    my $ofile_config = "$ofile_prefix-config.txt";
    my $ofile_ncftp = "$ofile_prefix-ncftp.txt";
    my $ofile_ftp = "$ofile_prefix-ftp.txt";
    
    print "ftp: @${ftp_config}\n";
    print "years: @years\n";
    print "months: @months\n";
    print "days: @days\n";
    print "hv: $indexes_hv\n";
    print "suffixes: $suffixes\n";


#    die "";
my $ftp = Net::FTP->new($ftp_site) 
    or die "Could not connect to $ftp_site: $!";
 
#print "Connected to $ftp_site\n";

$ftp->login($ftp_user, $ftp_password) 
    or die "Could not login to $ftp_site with user $ftp_user: $!";


$ftp->cwd($ftp_dir) 
    or die "Could not change remote working " . 
         "directory to $ftp_dir on $ftp_site";



open(OFILE_CONFIG,">$ofile_config") || die("Cannot Open File $ofile_ftp"); 
open(OFILE_FTP,">$ofile_ftp") || die("Cannot Open File $ofile_ftp"); 
open(OFILE_NCFTP,">$ofile_ncftp") || die("Cannot Open File $ofile_ncftp"); 

    print "script files: $ofile_config, $ofile_ftp $ofile_ncftp\n";
    print OFILE_CONFIG "#ftp: @${ftp_config}\n";
    print OFILE_CONFIG "#years: @years\n";
    print OFILE_CONFIG "#months: @months\n";
    print OFILE_CONFIG "#days: @days\n";
    print OFILE_CONFIG "#hv: $indexes_hv\n";
    print OFILE_CONFIG "#suffixes: $suffixes\n";

#print "Now in dir $ftp_dir\n";

print OFILE_FTP "open $ftp_site\n";
print OFILE_FTP "user $ftp_user $ftp_password\n";
print OFILE_FTP "bin\n";

foreach my $year (@years) {
#    my $mkdir= getcwd();
    mkdir ("$year");
    chdir ("$year");
    
#    print "year |$year|\n";
    foreach my $_month (@months) {
	my $month = sprintf("%02d",$_month);
#	print "month |$month|\n";
	foreach my $_day (@days) {
	    my $day = sprintf("%02d",$_day);
	    my $tmp_dir = "$year.$month.$day";
	    @remote_files = $ftp->ls($tmp_dir);
	    @filtered_files1 = grep (/$indexes_hv/, @remote_files);
	    @filtered_files2 = grep (/\.$suffixes$/, @filtered_files1);
#	    print "remote_files: @remote_files\n";
#	    print "filtred_files1: @filtered_files1\n";
#	    print "filtred_files2: @filtered_files2\n";
	    foreach my $tmp_file (@filtered_files2) {
#		    print "get MODIS_Dailies_B/MOLT/MOD09GQ.005/2011.08.01/MOD09GQ.A2011213.h13v10.005.2011215053310.hdf MOD09GQ.A2011213.h13v10.005.2011215053310.hdf
#		print "get -c $ftp_dir/$tmp_file\n";
#		print "ncftpget -bb -u $ftp_user -p $ftp_password ftp://$ftp_site/$ftp_dir/$tmp_file\n";
		print OFILE_FTP "get $ftp_dir/$tmp_file\n";
		print OFILE_NCFTP "ncftpget -bb -u $ftp_user -p $ftp_password $ftp_site . $ftp_dir/$tmp_file\n";
	    }
		

#		$ftp->cwd(".."); 
	}
    }
}

#die "";

$ftp->quit();


print OFILE_NCFTP "ncftpbatch  -D\n";

close(OFILE_FTP);
close(OFILE_NCFTP);


}
1;
