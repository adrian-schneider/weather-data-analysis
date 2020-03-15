package wdatemptime;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use SvgGraphNjs qw(:Basic :Shapes :Axis);
use JMAWeatherDB qw(:Basic);
use wdada;
use wdagraph;
use Statistics::Regression;
use List::Util qw(min max);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  drawStationTempTime
);
%EXPORT_TAGS = (
  Basic  => [qw(&drawStationTempTime)]
);

my $g_draw_dots_char = '';
my $g_reg = 0;
my @g_points_x;
my @g_points_y;

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
  @g_points_x = ();
  @g_points_y = ();
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
  my $yearf = $year + $month/12 - 1982;
  $g_reg->include($temp, [1.0, $yearf]);
  push @g_points_x, $yearf;
  push @g_points_y, $temp;
}

sub drawTempVsTime {
  my ($rn
    , $station_no
    , $station_name
    , $station_country
    , $station_long
    , $station_lat
    , $station_alt
  ) = @_;
  if ($station_no != 6660) { return; }
  print "$station_no $station_name $station_country\n";

  my $data_count = $g_reg->n;
  if ($data_count <= 10) {
     print "too little data ($data_count) on $station_no, $station_name\n";
     return;
  }

  if ('' eq $g_draw_dots_char) {
    plotPoint;
  }
  else {
    plotAlpha;
  }

  for (my $i = 0; $i < $data_count; $i++) {
    if ('' eq $g_draw_dots_char) {
      plot(mapX($g_points_x[$i]), mapY($g_points_y[$i]));
    }
    else {
      plot(mapX($g_points_x[$i])-textW('x')/2, mapY($g_points_y[$i])+textH()/2);
      text($g_draw_dots_char, 0);
    }
  }

  my @lrth = $g_reg->theta;
  plotLine;
  plot(mapX(0), mapY($lrth[0]));
  plot(mapX(2020-1982), mapY($lrth[0] + (2020-1982)*$lrth[1]));

  #print "y0   : " . $lrth[0] . "\n";
  #print "Dy/Dx: " . $lrth[1] . "\n";
}

sub drawStationTempTime {
  my $dots_char = shift;
  $g_draw_dots_char = $dots_char;
  wdada::resetCallbackRefs;
  $wdada::g_station_location_callback_ref = \&drawTempVsTime;
  $wdada::g_station_data_calback_pre_ref = \&dataCallbackPre;
  $wdada::g_station_data_filter_ref = \&dataFilter;
  $wdada::g_station_data_callback_ref = \&dataCallback;
  newPage;
  my %map = (
      x0 =>    0
    , x1 => 2020 - 1982
    , dx =>    1
    , y0 =>  -10
    , y1 =>   25
    , dy =>    1
  );
  wdagraph::setMap(\%map);
  wdagraph::setLegend(wdagraph::getTimeTempLegendRef);
  wdagraph::drawAxis;
  #wdagraph::drawRegionLabels;
  wdada::runQuery;
  endPage;
}

1;
