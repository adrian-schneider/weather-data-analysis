package wdatempmap;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use SvgGraphNjs qw(:Basic :Shapes :Axis);
use JMAWeatherDB qw(:Basic);
use wdada;
use wdagraph;
use Statistics::Regression;

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  drawStationTempMap
);
%EXPORT_TAGS = (
  Basic  => [qw(&drawStationTempMap)]
);

my $g_draw_dots_char = '';
my $g_reg = 0;

sub dataCallbackPre {
  my ($rn
    , $station_no
    , $station_name
    , $station_country
    , $station_long
    , $station_lat
    , $station_alt
  ) = @_;
  #print "$station_no $station_name\n";
  $g_reg = Statistics::Regression->new( "regression", [ "const", "someX" ] );
}

sub dataFilter {
  my $data_ref = shift;
  return
       '' ne $data_ref->[JMAWeatherDB::DB_DATA_YEAR]
    && '' ne $data_ref->[JMAWeatherDB::DB_DATA_MONTH]
    && '' ne $data_ref->[JMAWeatherDB::DB_DATA_TEMP_MEAN]
  ;
}

sub dataCallback {
  my $data_ref = shift;
  my ($year, $month, $temp) = (
      $data_ref->[JMAWeatherDB::DB_DATA_YEAR]
    , $data_ref->[JMAWeatherDB::DB_DATA_MONTH]
    , $data_ref->[JMAWeatherDB::DB_DATA_TEMP_MEAN]
  );
  my $yearf = $year + $month/12 - 1982.5;
  $g_reg->include($temp, [1.0, $yearf]);
}

sub drawStationAtLongLat {
  my ($rn
    , $station_no
    , $station_name
    , $station_country
    , $station_long
    , $station_lat
    , $station_alt
  ) = @_;
  #print "\n";

  my $data_count = $g_reg->n;
  if ($data_count <= 10) {
     print "too little data ($data_count) on $station_no, $station_name\n";
     return;
  }

  my @lrth = $g_reg->theta;
  #print "y0   : " . $lrth[0] . "\n";
  #print "Dy/Dx: " . $lrth[1] . "\n";

  #wdagraph::setRegionColor($rn);
  setColor(abs($lrth[1]) > (0.2/12) ?
    ($lrth[1] > 0 ? SvgGraphNjs::RED : SvgGraphNjs::BLUE)
    : SvgGraphNjs::GREEN
  );

  if ('' eq $g_draw_dots_char) {
    plot(mapX($station_long), mapY($station_lat));
  }
  else {
    plot(mapX($station_long)-textW('x')/2, mapY($station_lat)+textH()/2);
    text($g_draw_dots_char, 0);
  }
}

sub drawStationTempMap {
  my (
      $map_ref
    , $dots_char
  ) = @_;
  $g_draw_dots_char = $dots_char;
  wdada::resetCallbackRefs;
  $wdada::g_station_location_callback_ref = \&drawStationAtLongLat;
  $wdada::g_station_data_calback_pre_ref = \&dataCallbackPre;
  $wdada::g_station_data_filter_ref = \&dataFilter;
  $wdada::g_station_data_callback_ref = \&dataCallback;
  newPage;
  wdagraph::setMap($map_ref);
  wdagraph::setLegend(wdagraph::getLongLatLegendRef);
  wdagraph::drawAxis;
  #wdagraph::drawRegionLabels;
  if ('' eq $g_draw_dots_char) {
    plotPoint;
  }
  else {
    plotAlpha;
  }
  wdada::runQuery;
  endPage;
}

1;
