package wdagraph;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use SvgGraphNjs qw(:Basic :Shapes :Axis);
use JMAWeatherDB qw(:Basic);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  setRegionColor drawRegionLabels getLongLatMapRef setMap getLongLatLegendRef
  getTimeTempLegendRef setLegend drawAxis
);
%EXPORT_TAGS = (
  Basic  => [qw(&setRegionColor &drawRegionLabels &getLongLatMapRef &setMap &getTimeTempLegendRef
  &getLongLatLegendRef &setLegend &drawAxis)]
);

use constant GRAPH_X      => 100;
use constant GRAPH_Y      => 100;
use constant GRAPH_W      => 800;
use constant GRAPH_H      => 500;
use constant GRAPH_XW     => GRAPH_X + GRAPH_W;
use constant GRAPH_YH     => GRAPH_Y + GRAPH_H;
use constant TITLE_X      => GRAPH_X;
use constant TITLE_Y      => GRAPH_Y - 50;
use constant XAXISLABEL_X => GRAPH_X + GRAPH_W/2;
use constant XAXISLABEL_Y => GRAPH_YH + 35;
use constant YAXISLABEL_X => GRAPH_X - 75;
use constant YAXISLABEL_Y => GRAPH_Y + GRAPH_H/2;
use constant LEGEND_X     => GRAPH_X;
use constant LEGEND_DX    => 40;
use constant LEGEND_Y     => GRAPH_YH + 35;

my $g_records_processed;
my $g_records_selected;
my $g_data_source_name = 'Data Source: JMA'; # Japan Meteorological Agency

my %g_map;
my %g_legend;

sub setRegionColor {
  my $region_no = shift;
  if ($region_no == JMAWeatherDB::REGION_NO_ASIA_SIBERIA) {
    setColor(SvgGraphNjs::RED);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_EUROPE) {
    setColor(SvgGraphNjs::ORANGE);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_AFRICA) {
    setColor(SvgGraphNjs::YELLOW);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_NORTHAMERICA) {
    setColor(SvgGraphNjs::GREEN);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_SOUTHAMERICA) {
    setColor(SvgGraphNjs::BLUE);
  }
  elsif ($region_no == JMAWeatherDB::REGION_NO_SOUTHEASTASIA_OCEANIA) {
    setColor(SvgGraphNjs::PURPLE);
  }
  else {
    setColor(SvgGraphNjs::WHITE);
  }
}

sub drawRegionLabels {
  plotAlpha;
  for (my $region_no = 1; $region_no <= JMAWeatherDB::REGION_NO_MAX; $region_no++) {
    setRegionColor($region_no);
    setChrSize(SvgGraphNjs::TINY);
    my $rn3 = regionName3($region_no);
    if ($region_no == JMAWeatherDB::REGION_NO_ASIA_SIBERIA) {
      plot(LEGEND_X, LEGEND_Y);
      text($rn3, 0);
    }
    elsif ($region_no == JMAWeatherDB::REGION_NO_EUROPE) {
      plot(LEGEND_X + LEGEND_DX, LEGEND_Y);
      text($rn3, 0);
    }
    elsif ($region_no == JMAWeatherDB::REGION_NO_AFRICA) {
      plot(LEGEND_X + 2*LEGEND_DX, LEGEND_Y);
      text($rn3, 0);
    }
    elsif ($region_no == JMAWeatherDB::REGION_NO_NORTHAMERICA) {
      plot(LEGEND_X + 3*LEGEND_DX, LEGEND_Y);
      text($rn3, 0);
    }
    elsif ($region_no == JMAWeatherDB::REGION_NO_SOUTHAMERICA) {
      plot(LEGEND_X + 4*LEGEND_DX, LEGEND_Y);
      text($rn3, 0);
    }
    elsif ($region_no == JMAWeatherDB::REGION_NO_SOUTHEASTASIA_OCEANIA) {
      plot(LEGEND_X + 5*LEGEND_DX, LEGEND_Y);
      text($rn3, 0);
    }
  }
}

sub getLongLatMapRef {
  my %map = (
      x0 => -180.0
    , x1 =>  180.0
    , dx =>   30.0
    , y0 =>  -90.0
    , y1 =>   90.0
    , dy =>   15.0
  );
  return \%map;
}

sub getLongLatLegendRef {
  my %legend = (
      title  => 'Weather Station Locations'
    , xtitle => 'Long'
    , xunit  => '(deg)'
    , ytitle => 'Lat'
    , yunit  => '(deg)'
  );
  return \%legend;
}

sub getTimeTempLegendRef {
  my %legend = (
      title  => 'Temperature vs Time'
    , xtitle => 'Time'
    , xunit  => '(Year)'
    , ytitle => 'Temp'
    , yunit  => '(dgC)'
  );
  return \%legend;
}

sub setMap {
  my $map_ref = shift;
  %g_map = %$map_ref;
}

sub setLegend {
  my $legend_ref = shift;
  %g_legend = %$legend_ref;
}

sub drawAxis {
  setColor(SvgGraphNjs::GREEN);
  setChrSize(SvgGraphNjs::MEDIUM);
  plotAlpha;
  plot(TITLE_X, TITLE_Y);
  text($g_legend{title}, 0);
  plot(XAXISLABEL_X, XAXISLABEL_Y);
  text($g_legend{xtitle}.' '.$g_legend{xunit}, 0);
  plot(YAXISLABEL_X, YAXISLABEL_Y);
  text($g_legend{ytitle}, SvgGraphNjs::NEWLINE);
  text($g_legend{yunit}, 0);
  setChrSize(SvgGraphNjs::TINY);
  plot(GRAPH_XW - textW($g_data_source_name), LEGEND_Y);
  text($g_data_source_name, 0);
  mapDef($g_map{x0}, $g_map{y0}, $g_map{x1}, $g_map{y1}, GRAPH_X, GRAPH_Y, GRAPH_XW-1, GRAPH_YH-1);
  my $fmt = "%.0f";
  axis(GRAPH_X , GRAPH_YH, GRAPH_W, 0, $g_map{x0}, $g_map{x1}, $g_map{dx}, $fmt, 1);
  axis(GRAPH_X , GRAPH_Y , GRAPH_H, 2, $g_map{y0}, $g_map{y1}, $g_map{dy}, $fmt, 1);
  axis(GRAPH_X , GRAPH_Y , GRAPH_W, 1, $g_map{x0}, $g_map{x1}, $g_map{dx}, $fmt, 1);
  axis(GRAPH_XW, GRAPH_Y , GRAPH_H, 3, $g_map{y0}, $g_map{y1}, $g_map{dy}, $fmt, 1);
}

1;
