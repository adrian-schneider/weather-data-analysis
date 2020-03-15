package wdada;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use JMAWeatherDB qw(:Basic);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  resetCallbackRefs runQuery
);
%EXPORT_TAGS = (
  Basic  => [qw(&resetCallbackRefs &runQuery)]
);

my $g_datasets_processed = 0;
my $g_datasets_selected  = 0;
my $g_datasets_shown     = 0;
my $g_records_processed  = 0;
my $g_records_selected   = 0;
my $g_records_count      = 0;

our $g_verbose = 0;

our $g_station_location_callback_ref = 0;
our $g_station_data_callback_ref     = 0;
our $g_station_data_filter_ref       = 0;
our $g_station_data_calback_pre_ref  = 0;
our $g_station_data_calback_post_ref = 0;

our %g_filter_by = (
    station_long_min => ''
  , station_long_max => ''
  , station_lat_min  => ''
  , station_lat_max  => ''
  , station_alt_min  => ''
  , station_alt_max  => ''
  , station_region   => ''
  , station_name     => ''
  , station_country  => ''
);

sub resetCallbackRefs {
  $g_station_location_callback_ref = 0;
  $g_station_data_callback_ref     = 0;
  $g_station_data_filter_ref       = 0;
  $g_station_data_calback_pre_ref  = 0;
  $g_station_data_calback_post_ref = 0;
}

sub stationFilter {
  my (
      $rn
    , $station_no
    , $station_name
    , $station_country
  ) = @_;
  return (
       ($g_filter_by{station_country} eq '' || $station_country =~ $g_filter_by{station_country})
    && ($g_filter_by{station_name} eq ''    || $station_name =~ $g_filter_by{station_name})
  );
}

sub stationCallback {
  my (
      $station_data_file
    , $rn
    , $station_no
    , $station_name
    , $station_country
  ) = @_;

  my (
      $station_long
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
    if ($g_verbose) {
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
    }

    if (0 != $g_station_data_calback_pre_ref) {
      $g_station_data_calback_pre_ref->(
          $rn
        , $station_no
        , $station_name
        , $station_country
        , $station_long
        , $station_lat
        , $station_alt
      );
    }

    if (
         0 != $g_station_data_filter_ref
      || 0 != $g_station_data_callback_ref
    ) {
      ($g_records_processed, $g_records_selected) = foreachStationData(
          $fh
        , $g_station_data_filter_ref
        , $g_station_data_callback_ref
      );
      if ($g_verbose) {
        print "records processed : $g_records_processed\n";
        print "records selected  : $g_records_selected\n";
        print "\n";
      }
    }

    if (0 != $g_station_data_calback_post_ref) {
      $g_station_data_calback_post_ref->(
          $g_records_processed
        , $g_records_selected
      );
    }

    if (0 != $g_station_location_callback_ref) {
      $g_station_location_callback_ref->(
          $rn
        , $station_no
        , $station_name
        , $station_country
        , $station_long
        , $station_lat
        , $station_alt
      );
    }

    $g_datasets_shown++;
  }
  close $fh;

  #return $g_datasets_shown < 10;
  return 1;
}

sub runQuery {
  ($g_datasets_processed, $g_datasets_selected) = foreachStationPerRegion(
      $g_filter_by{station_region} eq '' ? 0 : $g_filter_by{station_region}
    , \&stationFilter
    , \&stationCallback
  );

  print "datasets processed: $g_datasets_processed\n";
  print "datasets selected : $g_datasets_selected\n";
  print "datasets shown . .: $g_datasets_shown\n";
}

1;
