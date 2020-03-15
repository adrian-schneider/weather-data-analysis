package wdalonglatmap;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use SvgGraphNjs qw(:Basic :Shapes :Axis);
use JMAWeatherDB qw(:Basic);
use wdada;
use wdagraph;

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  drawStationLongLatMap
);
%EXPORT_TAGS = (
  Basic  => [qw(&drawStationLongLatMap)]
);

my $g_draw_dots_char = '';

sub drawStationAtLongLat {
  my ($rn
    , $station_no
    , $station_name
    , $station_country
    , $station_long
    , $station_lat
    , $station_alt
  ) = @_;
  wdagraph::setRegionColor($rn);
  if ('' eq $g_draw_dots_char) {
    plot(mapX($station_long), mapY($station_lat));
  }
  else {
    plot(mapX($station_long)-textW('x')/2, mapY($station_lat)+textH()/2);
    text($g_draw_dots_char, 0);
  }
}

sub drawStationLongLatMap {
  my (
      $map_ref
    , $dots_char
  ) = @_;
  $g_draw_dots_char = $dots_char;
  wdada::resetCallbackRefs;
  $wdada::g_station_location_callback_ref = \&drawStationAtLongLat;
  newPage;
  wdagraph::setMap($map_ref);
  wdagraph::drawAxis;
  wdagraph::drawRegionLabels;
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
