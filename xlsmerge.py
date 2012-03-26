#!/usr/bin/perl -w
use strict;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use File::Glob qw(bsd_glob);
use Getopt::Long;
use POSIX qw(strftime);
use File::Basename;

GetOptions(
    'output|o=s' => \my $outfile,
    'strftime|t' => \my $do_strftime,
) or die;

if ($do_strftime) {
    $outfile = strftime $outfile, localtime;
};

my $output = Spreadsheet::WriteExcel->new($outfile)
    or die "Couldn't create '$outfile': $!";

for (@ARGV) {
    my ($filename,$sheetname,$targetname);
    my @files;
    if (m!^(.*\.xls):(.*?)(?::([\w ]+))$!) {
        ($filename,$sheetname,$targetname) = ($1,qr($2),$3);
        warn $filename;
        if ($do_strftime) {
            $filename = strftime $filename, localtime;
        };
        @files = glob $filename;
    } else {
        ($filename,$sheetname,$targetname) = ($_,qr(.*),undef);
        if ($do_strftime) {
            $filename = strftime $filename, localtime;
        };
        push @files, glob $filename;
    };

    my $i=0;
    for my $f (@files) {
	$i++;
#	print $f . "-" . $i . "\n";
        my $excel = Spreadsheet::ParseExcel::Workbook->Parse($f);
        foreach my $sheet (@{$excel->{Worksheet}}) {
            if ($sheet->{Name} !~ /$sheetname/) {
                warn "Skipping '" . $sheet->{Name} . "' (/$sheetname/) ";
                next;
            };
            #$targetname ||= $sheet->{Name};
	    my $bname = basename($f,".xls");
            $targetname ||= substr $bname, 0, 31;#"Sheet".$i;
#	    print $sheet->{Name} . "/" . $targetname . "\n";
            #warn sprintf "Copying %s to %s\n", $sheet->{Name}, $targetname;

            my $s = $output->add_worksheet($targetname);
            $sheet->{MaxRow} ||= $sheet->{MinRow};
            foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
                my @rowdata = map {
                    $sheet->{Cells}->[$row]->[$_]->{Val};
                } $sheet->{MinCol} ..  $sheet->{MaxCol};
                $s->write($row,0,\@rowdata);
            }
        }
    };
};

$output->close;
