package JMAWeatherDB;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  regionName3 regionName getStationDataFileSuffix getStationListPerRgionFile getStationDataPerRegionFile
  foreachStationPerRegion getStationLocation foreachStationData
);
%EXPORT_TAGS = (
  Basic  => [qw(&regionName3 &regionName &getStationDataFileSuffix &getStationListPerRgionFile &getStationDataPerRegionFile
    &foreachStationPerRegion &getStationLocation &foreachStationData)]
);

use constant REGION_NO_MAX                   => 6;
use constant REGION_NO_ALL                   => 0;
use constant REGION_NO_ASIA_SIBERIA          => 1;
use constant REGION_NO_EUROPE                => 2;
use constant REGION_NO_AFRICA                => 3;
use constant REGION_NO_NORTHAMERICA          => 4;
use constant REGION_NO_SOUTHAMERICA          => 5;
use constant REGION_NO_SOUTHEASTASIA_OCEANIA => 6;

use constant DB_META_DIR                 => './JMA/meta';
use constant DB_DATA_DIR                 => './JMA/data_';
use constant DB_DATA_FILE_PRFIX          => 'jma_data_';
use constant DB_STATION_LIST_FILE_PREFIX => 'jma_stations_region_';

use constant DB_DATA_YEAR           =>  0;
use constant DB_DATA_MONTH          =>  1;
use constant DB_DATA_TEMP_MEAN      =>  2;
use constant DB_DATA_TEMP_MAX       =>  3;
use constant DB_DATA_TEMP_MIN       =>  4;
use constant DB_DATA_PRECIP         =>  5;
use constant DB_DATA_TEMP_MEAN_NORM =>  6;
use constant DB_DATA_PRECIP_NORM    =>  7;
use constant DB_DATA_SPI_3_MONTH    =>  8;
use constant DB_DATA_SPI_6_MONTH    =>  9;
use constant DB_DATA_SPI_12_MONTH   => 10;

sub regionName3 {
  my $region_no = shift;
  if ($region_no == REGION_NO_ASIA_SIBERIA) {
    return 'ASI';
  }
  elsif ($region_no == REGION_NO_EUROPE) {
    return 'EUR';
  }
  elsif ($region_no == REGION_NO_AFRICA) {
    return 'AFR';
  }
  elsif ($region_no == REGION_NO_NORTHAMERICA) {
    return 'NAM';
  }
  elsif ($region_no == REGION_NO_SOUTHAMERICA) {
    return 'SAM';
  }
  elsif ($region_no == REGION_NO_SOUTHEASTASIA_OCEANIA) {
    return 'SAO';
  }
  else {
    return '---';
  }
}

sub regionName {
  my $region_no = shift;
  if ($region_no == REGION_NO_ASIA_SIBERIA) {
    return 'Asia/Siberia';
  }
  elsif ($region_no == REGION_NO_EUROPE) {
    return 'Europe';
  }
  elsif ($region_no == REGION_NO_AFRICA) {
    return 'Africa';
  }
  elsif ($region_no == REGION_NO_NORTHAMERICA) {
    return 'Northamerica';
  }
  elsif ($region_no == REGION_NO_SOUTHAMERICA) {
    return 'Southamerica';
  }
  elsif ($region_no == REGION_NO_SOUTHEASTASIA_OCEANIA) {
    return 'Southeast Asia/Oceania';
  }
  else {
    return '------';
  }
}

sub getStationDataFileSuffix {
  return '_198206_201911.dat'
}

sub getStationListPerRgionFile {
  my $region_no = shift;
  return DB_META_DIR . '/'
    . DB_STATION_LIST_FILE_PREFIX . $region_no . '.dat';
}

sub getStationDataPerRegionFile {
  my ($region_no, $station_no) = @_;
  return DB_DATA_DIR . $region_no . '/'
    . DB_DATA_FILE_PRFIX . $station_no . getStationDataFileSuffix();
}

sub foreachStationPerRegion {
  my ($region_no                  # 0 for all regions
    , $filter_ref                 # \&filter(
                                  #   $region_no
                                  # , $station_no
                                  # , $station_name
                                  # , $station_country
                                  # ): select 0|1
    , $callback_ref               # \&callback(
                                  #   $station_data_file
                                  # , $region_no
                                  # , $station_no
                                  # , $station_name
                                  # , $station_country
                                  # ): continue 0|1
  ) = @_;
  my ($records_processed, $records_selected) = (0, 0);
  for (my $rn = ($region_no == 0 ? 1 : $region_no);
      ($rn <= REGION_NO_MAX) && (($rn == $region_no) || ($region_no == 0));
      $rn++
  ) {
    open(my $fh, '<', getStationListPerRgionFile($rn));
    while (my $line = <$fh>) {
      chomp($line);
      $records_processed++;
      my ($station_no, $station_name, $station_country) = split(';;', $line);
      my $station_data_file = getStationDataPerRegionFile($rn, $station_no);
      if (
        0 == $filter_ref || $filter_ref->(
            $rn
          , $station_no
          , $station_name
          , $station_country
        )
      ) {
        $records_selected++;
        last unless $callback_ref->(
            $station_data_file
          , $rn
          , $station_no
          , $station_name
          , $station_country
        );
      }
    }
    close $fh;
  }
  return ($records_processed, $records_selected);
}

sub getStationLocation {
  my ($station_data_fh     # open station data file handle
    , $station_long_ref    # \$station_longitude
    , $station_lat_ref     # \$station_latitude
    , $station_alt_ref     # \$station_altitude
  ) = @_;
  seek $station_data_fh, 0, 0;
  my $line = <$station_data_fh>;
  $line =~ /Lat:((?:\d+)?(?:\.\d*)?)([nNsS])/;
  $$station_lat_ref = $1 * (($2 eq 's' || $2 eq 'S') ? -1.0 : 1.0);
  $line =~ /Long:((?:\d+)?(?:\.\d*)?)([wWeE])/;
  $$station_long_ref = $1 * (($2 eq 'w' || $2 eq 'W') ? -1.0 : 1.0);
  $line =~ /Height:((?:\d+)?(?:\.\d*)?)/;
  $$station_alt_ref = $1;
}

sub foreachStationData {
  my ($station_data_fh    # open station data file handle
    , $filter_ref         # \&filter(\@data)
    , $callback_ref       # \&callback(\@data)
  ) = @_;
  seek $station_data_fh, 0, 0;
  <$station_data_fh>;
  <$station_data_fh>;
  <$station_data_fh>;
  my ($records_processed, $records_selected) = (0, 0);
  while (my $line = <$station_data_fh>) {
    $line =~ s/\s+//g;
    $records_processed++;
    my @data = split(',', $line, 16);
    if (0 == $filter_ref || $filter_ref->(\@data)) {
      if (0 != $callback_ref) {
        $records_selected++;
        last unless ($callback_ref->(\@data));
      }
    }
  }
  return ($records_processed, $records_selected);
}

1;
