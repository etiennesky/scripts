#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use Spreadsheet::WriteExcel 2.11; # so unicode works right
use Getopt::Long;

my $enc;
my $split;

GetOptions ("enc=s" => \$enc,
            "split=s" => \$split);
$enc ||= "iso-8859-1";

if (@ARGV < 2)
 { die "Useage: filename.csv filename.xls\n" }
my ($in_filename, $out_filename) = @ARGV;

my $csv = Text::CSV->new();

# open the in and out file
open my $in_fh, "<:encoding($enc)", $in_filename
  or die "can't open $in_filename: $!";
my $workbook = Spreadsheet::WriteExcel->new($out_filename);

my @titles;
my $country_index;
if ($split)
{
  @titles = read_line_as_csv(scalar(<$in_fh>));
  foreach (0..$#titles)
  {
    $country_index = $_ if $titles[$_] eq $split;
  }
  unless (defined($country_index))
    { die "Can't find column $split" }
}

my %row;
my %worksheets;
while (<$in_fh>)
{
  # parse the line as a CSV
  my @fields = read_line_as_csv($_);

  # look up what field we're splitting on and use that to determine
  # what worksheet to use - we might just be using the one if we're
  # not splitting
  my $country = ($split) ? $fields[ $country_index ] : "Worksheet1";
  my $worksheet = $worksheets{ $country };

  # create a new worksheet if we need to
  unless ($worksheet)
  {
    $worksheet = $workbook->add_worksheet( $country );
    $worksheets{ $country } = $worksheet;
    $worksheet->write_row(0,0,\@titles);
    $row{ $country } = 1;
  }

  $worksheet->write_row($row{ $country }, 0, \@fields);
  $row{ $country }++;
}

sub read_line_as_csv
{
  local $_ = shift;

  # really nasty hack to make parsing non ascii chars possible
  # don't use HTML::Entities for this as it depends on how it
  # was compiled if it can do this or not
  s/([&\200-\x{FFFD}])/sprintf('&#%x;',ord($1))/ge;
  $csv->parse($_);
  my @fields = $csv->fields;
  s/&#([a-f0-9]+);/chr(hex($1))/ge
    foreach @fields;

  return @fields;
}

=head1 NAME

csv2excel - covnert csv file to excel better than Excel X can

=head1 SYNOPSIS

  bash$ csv2excel --enc utf8 --split country foo.csv foo.xls

=head1 DESCRIPTION

Creates an excel file from a CSV file.  Does a better job
of it that Excel X on the mac too.

Normal useage is just to supply a input filename and an
output filename

  csv2excel foo.csv foo.xls

=head2 Encodings

You can tell the script what encoding your CSV file is in

  csv2excel --enc utf8 foo.csv foo.xls
  csv2excel --enc iso-8859-7 foo.csv foo.xls

If you don't supply an C<enc> it'll assume C<iso-8859-1> - i.e.
latin-1 (The encodings supported on your system may vary, they're
whatever PerlIO can deal with).

The script can cope with creating unicode characters in an Excel file
quite happily - it does this automatically as needed.

=head2 Splitting up the output

You can also tell the script to split the workbook up into serveral
sheets, putting all the rows that have the same value for a particular
column on the same sheet.  To do this you need to use the C<--split>
option, passing the name of the column you want to split on as the
argument

  csv2excel --split country foo.csv foo.xls

=head1 COPYRIGHT

Fotango 2004, All rights reservered.

Originally written by Mark Fowler <mfowler@fotango.com>

=head1 SEE ALSO

L<utf16tolatin1> - turns the outpt of CocoaMySql into utf8 for
class persist style databases.

=cut
