#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use lib "./";
use JMAWeatherDB qw(:Basic);
#use SvgGraphNjs qw(:Basic :Shapes :Axis);

my $g_datasets_processed = 0;
my $g_datasets_selected  = 0;
my $g_datasets_shown     = 0;
my $g_records_processed  = 0;
my $g_records_selected   = 0;
my $g_records_count      = 0;

my %g_filter_by = (
    station_long_min => ''
  , station_long_max => ''
  , station_lat_min  => ''
  , station_lat_max  => ''
  , station_alt_min  => ''
  , station_alt_max  => ''
  , station_region   => 2
  , station_name     => ''
  , station_country  => 'SWITZ'
);

sub station_filter {
  my ($rn
    , $station_no
    , $station_name
    , $station_country
  ) = @_;
  return (
       ($g_filter_by{station_country} eq '' || $station_country =~ $g_filter_by{station_country})
    && ($g_filter_by{station_name} eq ''    || $station_name =~ $g_filter_by{station_name})
  );
  #return 1
}

sub data_filter {
  my $data_ref = shift;
  return
       '' ne $data_ref->[JMAWeatherDB::DB_DATA_YEAR]
    && '' ne $data_ref->[JMAWeatherDB::DB_DATA_MONTH]
    && '' ne $data_ref->[JMAWeatherDB::DB_DATA_TEMP_MEAN]
  ;
}

sub data_callback {
  my $data_ref = shift;
  my ($year, $month, $mean_temp) = (
      $data_ref->[JMAWeatherDB::DB_DATA_YEAR]
    , $data_ref->[JMAWeatherDB::DB_DATA_MONTH]
    , $data_ref->[JMAWeatherDB::DB_DATA_TEMP_MEAN]
  );
  my $yearf = $year + ($month - 1)/12.0;
  printf "    %4d %02d, %8.2f, %6.1f\n", $year, $month, $yearf, $mean_temp;
  $g_records_count++;
  my $do_continue = $g_records_count < 10;
  $g_records_count = 0 unless ($do_continue);
  return $do_continue;
}

sub station_callback {
  my ($station_data_file
    , $rn
    , $station_no
    , $station_name
    , $station_country
  ) = @_;

  my ($station_long
    , $station_lat
    , $station_alt
  ) = (0.0, 0.0, 0.0);

  open(my $fh, '<', $station_data_file);
  getStationLocation(
    $fh
    , \$station_long
    , \$station_lat
    , \$station_alt
  );

  my $location_selected =
       ($g_filter_by{station_lat_min} eq '' || $station_lat >= $g_filter_by{station_lat_min})
    && ($g_filter_by{station_lat_max} eq '' || $station_lat <= $g_filter_by{station_lat_max})
    && ($g_filter_by{station_long_min} eq '' || $station_long >= $g_filter_by{station_long_min})
    && ($g_filter_by{station_long_max} eq '' || $station_long <= $g_filter_by{station_long_max})
  ;

  # Stations exist with undefined altitude.
  if (
       ($g_filter_by{station_alt_min} ne '' || $g_filter_by{station_alt_max} ne '')
    && ($station_alt eq '')
  ) {
    $location_selected = 0;
    my $rnn = regionName($rn);
    print "*** Altitude undefined, ignoring station\n";
    print "    region . . . . : $rn, $rnn\n";
    print "    station no . . : $station_no\n";
    print "    station name . : $station_name\n";
    print "    station country: $station_country\n";
    print "\n";
  }
  else {
    $location_selected = $location_selected
      && ($g_filter_by{station_alt_min} eq '' || $station_alt >= $g_filter_by{station_alt_min})
      && ($g_filter_by{station_alt_max} eq '' || $station_alt <= $g_filter_by{station_alt_max})
    ;
  }
  # END Stations exist with undefined altitude.

  if ($location_selected) {
    my $rnn = regionName($rn);
    print "file . . . . . : $station_data_file\n";
    print "region . . . . : $rn, $rnn\n";
    print "station no . . : $station_no\n";
    print "station name . : $station_name\n";
    print "station country: $station_country\n";
    print "station long . : $station_long\n";
    print "station lat  . : $station_lat\n";
    print "station alt  . : $station_alt\n";
    print "\n";

    ($g_records_processed, $g_records_selected) = foreachStationData(
      $fh
      , \&data_filter
      , \&data_callback
    );
    print "records processed : $g_records_processed\n";
    print "records selected  : $g_records_selected\n";
    print "\n";

    $g_datasets_shown++;
  }
  close $fh;

  return $g_datasets_shown < 10;
}

($g_datasets_processed, $g_datasets_selected) = foreachStationPerRegion(
    $g_filter_by{station_region} eq '' ? 0 : $g_filter_by{station_region}
  , \&station_filter
  , \&station_callback
);

print "datasets processed: $g_datasets_processed\n";
print "datasets selected : $g_datasets_selected\n";
print "datasets shown . .: $g_datasets_shown\n";
