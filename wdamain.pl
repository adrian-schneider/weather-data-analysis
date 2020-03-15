#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use lib "./";
use SvgGraphNjs qw(:Basic :Shapes :Axis);
use wdada;
use wdagraph;
use wdalonglatmap;
use wdatempmap;
use wdatemptime;

$wdada::g_verbose = 0;

my %g_filter_eur_w60_e60_n30_n75 = (
    station_long_min => -60
  , station_long_max => 60
  , station_lat_min  => 30
  , station_lat_max  => 75
  , station_alt_min  => ''
  , station_alt_max  => ''
  , station_region   => 2
  , station_name     => ''
  , station_country  => ''
);

my %g_filter_switzerland_e00_e12_n44_n52 = (
    station_long_min => 0
  , station_long_max => 12
  , station_lat_min  => 44
  , station_lat_max  => 52
  , station_alt_min  => ''
  , station_alt_max  => ''
  , station_region   => 2
  , station_name     => ''
  , station_country  => 'SWITZERLAND'
);

%wdada::g_filter_by = %g_filter_switzerland_e00_e12_n44_n52;

sub getMapRefFromFilter {
  my $filter_ref = shift;
  my $mapLongLat_ref = wdagraph::getLongLatMapRef;
  my %map = %$mapLongLat_ref;
  my $xdrty = 0;
  my $ydrty = 0;
  $map{dx} = ($map{x1} - $map{x0}) / 12.0;
  $map{dy} = ($map{y1} - $map{y0}) / 12.0;
  if ('' ne $filter_ref->{station_long_min}) { $map{x0} = $filter_ref->{station_long_min}; $xdrty = 1; }
  if ('' ne $filter_ref->{station_long_max}) { $map{x1} = $filter_ref->{station_long_max}; $xdrty = 1;  }
  if ('' ne $filter_ref->{station_lat_min})  { $map{y0} = $filter_ref->{station_lat_min}; $ydrty = 1;  }
  if ('' ne $filter_ref->{station_lat_max})  { $map{y1} = $filter_ref->{station_lat_max}; $ydrty = 1;  }
  if ($xdrty) { $map{dx} = ($map{x1} - $map{x0}) / 10.0; }
  if ($ydrty) { $map{dy} = ($map{y1} - $map{y0}) / 10.0; }
  return \%map;
}

my $map_ref = 1 ?
    getMapRefFromFilter(\%wdada::g_filter_by)
  : wdagraph::getLongLatMapRef
;

#wdalonglatmap::drawStationLongLatMap($map_ref, 'X');
#wdatempmap::drawStationTempMap($map_ref, 'X');

wdatemptime::drawStationTempTime('');
