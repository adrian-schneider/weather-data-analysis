#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use lib "./";
use SvgGraphNjs qw(:Basic :Shapes :Axis);
use JMAWeatherDB qw(:Basic);

use constant GRAPH_X => 100;
use constant GRAPH_Y => 100;
use constant GRAPH_W => 800;
use constant GRAPH_H => 500;
use constant GRAPH_XW => GRAPH_X + GRAPH_W;
use constant GRAPH_YH => GRAPH_Y + GRAPH_H;
use constant TITLE_X => GRAPH_X;
use constant TITLE_Y => GRAPH_Y - 50;
use constant XAXISLABEL_X => GRAPH_X + GRAPH_W/2;
use constant XAXISLABEL_Y => GRAPH_YH + 35;
use constant YAXISLABEL_X => GRAPH_X - 75;
use constant YAXISLABEL_Y => GRAPH_Y + GRAPH_H/2;
use constant LEGEND_X => GRAPH_X;
use constant LEGEND_DX => 40;
use constant LEGEND_Y => GRAPH_YH + 35;

my $g_records_processed;
my $g_records_selected;

sub stationFilter {
  my ($rn
    , $station_no
    , $station_name
    , $station_country
  ) = @_;
  #return $station_country =~ /SWITZ/;
  #print "  station: $station_no\n";
  return 1;
}

sub stationCallback {
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
  plot(mapX($station_long), mapY($station_lat));
  close $fh;
  #return ++$g_records_processed <= 10;
  return 1;
}

sub drawRegionLabel {
  my $region_no = shift;
  plotAlpha;
  setChrSize(SvgGraphNjs::TINY);
  setColor(SvgGraphNjs::WHITE);
  my $rn3 = regionName3($region_no);
  if ($region_no == JMAWeatherDB::REGION_NO_ASIA_SIBERIA) {
    setColor(SvgGraphNjs::RED);
    plot(LEGEND_X, LEGEND_Y);
    text($rn3, 0);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_EUROPE) {
    setColor(SvgGraphNjs::ORANGE);
    plot(LEGEND_X + LEGEND_DX, LEGEND_Y);
    text($rn3, 0);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_AFRICA) {
    setColor(SvgGraphNjs::YELLOW);
    plot(LEGEND_X + 2*LEGEND_DX, LEGEND_Y);
    text($rn3, 0);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_NORTHAMERICA) {
    setColor(SvgGraphNjs::GREEN);
    plot(LEGEND_X + 3*LEGEND_DX, LEGEND_Y);
    text($rn3, 0);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_SOUTHAMERICA) {
    setColor(SvgGraphNjs::BLUE);
    plot(LEGEND_X + 4*LEGEND_DX, LEGEND_Y);
    text($rn3, 0);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_SOUTHEASTASIA_OCEANIA) {
    setColor(SvgGraphNjs::PURPLE);
    plot(LEGEND_X + 5*LEGEND_DX, LEGEND_Y);
    text($rn3, 0);
  }
}

sub doForAllStations {
  my $region_no = shift;
  for (my $rn = 1; $rn <= JMAWeatherDB::REGION_NO_MAX; $rn++) {
    next unless ((0 == $region_no) || ($rn == $region_no));
    drawRegionLabel($rn);
    plotPoint;
    ($g_records_processed, $g_records_selected) = foreachStationPerRegion(
      $rn
      , \&stationFilter
      , \&stationCallback
    );
    my $rnm = regionName($rn);
    print "region . . . . . : $rn, $rnm\n";
    print "records processed: $g_records_processed\n";
    print "records selected : $g_records_selected\n";
  }
}

sub drawAxis {
  setColor(SvgGraphNjs::GREEN);
  setChrSize(SvgGraphNjs::MEDIUM);
  plotAlpha;
  plot(TITLE_X, TITLE_Y);
  text("Weather Station Locations", 0);
  plot(XAXISLABEL_X, XAXISLABEL_Y);
  text("Long (deg)", 0);
  plot(YAXISLABEL_X, YAXISLABEL_Y);
  text("Lat", SvgGraphNjs::NEWLINE);
  text("(deg)", 0);
  setChrSize(SvgGraphNjs::TINY);
  plot(GRAPH_XW - 100, LEGEND_Y);
  text("Source: JMA", 0);
  axis(GRAPH_X , GRAPH_YH, GRAPH_W, 0, -180.0, 180.0, 30.0, "%.0f", 1);
  axis(GRAPH_X , GRAPH_Y , GRAPH_H, 2,  -90.0,  90.0, 15.0, "%.0f", 1);
  axis(GRAPH_X , GRAPH_Y , GRAPH_W, 1, -180.0, 180.0, 30.0, "%.0f", 1);
  axis(GRAPH_XW, GRAPH_Y , GRAPH_H, 3,  -90.0,  90.0, 15.0, "%.0f", 1);
}

sub setupMap {
  mapDef(-180.0, -90.0, 180.0, 90.0, GRAPH_X, GRAPH_Y, GRAPH_XW-1, GRAPH_YH-1);
}

newPage;
drawAxis;
setupMap;
doForAllStations(0);
endPage;
#copyPage;
