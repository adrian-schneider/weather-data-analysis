package SvgGraphNjs;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use File::Copy qw(copy);

$VERSION     = 1.01;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
  plotPoint plotLine plot plotAlpha newPage endPage copyPage setColor setChrSize textW textH
    home text setLineStyle
  ellipticArc ellipse
  axis mapDef mapX mapwX mapY mapwY
);
%EXPORT_TAGS = (
  Basic  => [qw(&plotPoint &plotLine &plot &plotAlpha &newPage &endPage &copyPage &setColor
    &setChrSize &textW &textH &home &text &setLineStyle)]
  , Shapes => [qw(&ellipticArc &ellipse)]
  , Axis => [qw(&axis &mapDef &mapX &mapwX &mapY &mapwY)]
);

use constant PLOTMODEALPHA => 0;
use constant PLOTMODELINE  => 1;
use constant PLOTMODEPOINT => 2;

use constant BLACK     =>  0;
use constant RED       =>  1;
use constant GREEN     =>  2;
use constant BLUE      =>  3;
use constant YELLOW    =>  4;
use constant PURPLE    =>  5;
use constant TURQUOISE =>  6;
use constant WHITE     =>  7;
use constant ORANGE    =>  8;
use constant PINK      =>  9;
use constant GREY      => 10;

# Standard text colors.
use constant HALFBRIGHT   => 11;
use constant NORMALBRIGHT => 12;
use constant DOUBLEBRIGHT => 13;

use constant TINY      =>  0;
use constant SMALL     =>  1;
use constant MEDIUM    =>  2;
use constant LARGE     =>  3;

use constant NOMOVE    =>  0;
use constant TOEND     =>  1;
use constant NEWLINE   =>  2;

use constant FULL      =>  0;
use constant DOTTED    =>  1;
use constant DASHDOT   =>  2;
use constant SMALLDASH =>  3;
use constant BIGDASH   =>  4;

our $screenwidth     = 1000;
our $screenheight    = 700;
our $paddingwidth    = 8;
our $paddingheight   = 8;
our $redrawinterval  = 500;
our $testmode        = 0;
our $forceinit       = 0;
our $graphpathname   = "./.svggraph";
our $indexfilename   = "${graphpathname}/index.html";
our $graphfilename   = "${graphpathname}/graph.html";
our $graphspoolname  = "${graphpathname}/graph.tmp";
our $graphspoolname2 = "${graphpathname}/graph2.tmp";
our $copydirname     = ".";
our @fontsizeSize    = (12, 15, 20, 25);
our @fontHeight      = (12, 15, 20, 25);
our @fontWidth       = (7, 9, 12, 15);
our $linestyle       = FULL;
our @linestyleStyle  = (
  ""
  , "stroke-dasharray:3,3"
  , "stroke-dasharray:10,5,3,5"
  , "stroke-dasharray:7,5"
  , "stroke-dasharray:15,5"
);
our $fontfamily      = "consolas,monospace";
our $defaultstyle    = "stroke:white";
our @colorcolor = (
  "black", "orangered", "limegreen", "deepskyblue",
  "yellow", "violet", "turquoise", "white",
  "orange", "lightpink", "lightgrey",
  "forestgreen", "limegreen", "lightgreen"
);

my $plotmode;
my $lastX;
my $lastY;
my $move;
my $fontsize;
my $graphspool;
my $color;

sub initvar {
  $plotmode = PLOTMODEALPHA;
  $lastX = 0;
  $lastY = 0;
  $move = 1;
  $fontsize = MEDIUM;
  $color = WHITE;
}

sub spool {
  my $str = shift;
  print $graphspool "$str\n";
}

sub getStyle {
  if ($plotmode == PLOTMODEALPHA) {
    return (
      qq(fill="$colorcolor[$color]" font-size="$fontsizeSize[$fontsize]" font-family="$fontfamily")
    );
  }
  elsif ($plotmode == PLOTMODELINE) {
    my $ls = $linestyleStyle[$linestyle];
    return qq(style="stroke:$colorcolor[$color];$ls");
  }
  elsif ($plotmode == PLOTMODEPOINT) {
    my $ls = $linestyleStyle[$linestyle];
    return qq(style="stroke:$colorcolor[$color];$ls");
  }
}

# Enter point plot mode.
sub plotPoint {
  $plotmode = PLOTMODEPOINT;
  $move = 0;
}

# Enter line plot mode and start a new line segment.
sub plotLine {
  $plotmode = PLOTMODELINE;
  $move = 1;
}

# Plot a point or a line or move to position.
# x coordinate
# y coordinate
sub plot {
  my ($x, $y) = @_;
  my $s = getStyle;
  $x = int($x);
  $y = int($y);
  if ($plotmode == PLOTMODELINE) {
    if (! $move) {
      spool(qq(<line x1="$lastX" y1="$lastY" x2="$x" y2="$y" $s/>));
    }
  }
  elsif ($plotmode == PLOTMODEPOINT) {
    my $x2 = $x + 1;
    my $y2 = $y + 1;
    spool(qq(<line x1="$x" y1="$y" x2="$x2" y2="$y2" $s/>));
  }
  $lastX = $x;
  $lastY = $y;
  $move = 0;
}

# Set alpha mode.
sub plotAlpha {
  $plotmode = PLOTMODEALPHA;
  $move = 1;
}

sub initialize {
  my $force = shift;
  if (! -d "$graphpathname") {
    mkdir($graphpathname)
      or die "cannot create $graphpathname:\n$!";
  }

  if (-e "$indexfilename" && ! $force) {
    return;
  }

  my $sw = $screenwidth + 2*$paddingwidth;
  my $sh = $screenheight + 2*$paddingheight;
  my $str =
    qq(
<!DOCTYPE html>
<style>html,body{margin:0 0 0 0;overflow:hidden;background-color:black;color:white;font-family:$fontfamily}</style>
<html><body>
<!--
<input id="hold" type="checkbox">HOLD<br>
-->
<iframe id="graph" scrolling="no" width="$sw" height="$sh" frameBorder="0" src="./graph.html">
</iframe>
<script>
function askGraphChanged() {
  //if (! document.getElementById("hold").checked) {
  {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
      if (this.readyState == 4 && this.status == 200) {
        if (xhttp.responseText.indexOf('T') != -1) {
          reload();
        }
      }
    };
    xhttp.open('GET', '/ask_graph_changed', true);
    xhttp.send();
  }
}
function reload() {
  var container = document.getElementById("graph");
  container.src = container.src;
}
setInterval(askGraphChanged, $redrawinterval);
</script>
</body></html>
    );

  open(my $of, ">", $indexfilename);
  print $of $str;
  close($of);
}

# Clear the screen and set alpha mode.
sub newPage {
  initvar;
  plotAlpha;

  initialize($forceinit);

  open($graphspool, ">", "$graphspoolname")
    or die "cannot open $graphspoolname for output:\n$!";
  spool(
    qq(
<svg height="$screenheight" width="$screenwidth" style="background-color:black;stroke-width:1">
    )
  );
  if ($testmode) {
    my $w = $screenwidth - 1;
    my $h = $screenheight - 1;
    spool(
      qq(
<line x1="0" y1="0" x2="$w" y2="$h" style="stroke:white"/>
<line x1="0" y1="0" x2="$w" y2="0" style="stroke:white"/>
<line x1="$w" y1="0" x2="$w" y2="$h" style="stroke:white"/>
<line x1="$w" y1="$h" x2="0" y2="$h" style="stroke:white"/>
<line x1="0" y1="$h" x2="0" y2="0" style="stroke:white"/>
      )
    );
  }
}

sub endPage {
  spool(qq(</svg>));
  close($graphspool);
  if (-e $graphfilename) {
    unlink($graphfilename)
      or die "cannot delete $graphfilename:\n$!";
  }
  rename($graphspoolname, $graphfilename)
    or die "cannot rename $graphspoolname to $graphfilename:\n$!\n";
}

# Store a copy of the screen in a file.
sub copyPage {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
    = localtime;
  my $fn = sprintf(
    "$copydirname/svgcopy-%04d%02d%02d-%02d%02d%02d.html"
    , $year+1900, $mon+1, $mday, $hour, $min, $sec
  );
  copy($graphfilename, $fn);
}

# Set the stroke color.
sub setColor {
  my $c = shift;
  $color = $c % 14;
}

# Set the character size.
# i 0: tiny
#   1: small
#   2: medium
#   3: large
sub setChrSize {
  my $i = shift;
  $fontsize = $i % 4;
}

# Set the line style.
# i 0: solid
#   1: dotted
#   2: dot-dash
#   3: short dash
#   4: long dash
sub setLineStyle {
  my $i = shift;
  $linestyle = $i % 5;
}

use constant PI  => 3.14159;
use constant PI2 => PI + PI;

# Draw an elliptic arc or pie slice.
# x   coordinate center
# y   coordinate center
# rx  coordinate radius
# ry  coordinate radius
# w0  0.0..1.0 start angle
# w1  0.0..1.0 end angle
# seg number of segments per full circle
# pie 0,1 draw as pie slice
sub ellipticArc {
  my ($x, $y, $rx, $ry, $w0, $w1, $seg, $pie) = @_;
  plotLine;
  my $w01 = $w0 * PI2;
  my $w11 = $w1 * PI2 * 1.005;
  my $d   = PI2 / $seg;
  if ($pie) {
    plot($x, $y);
  }
  for (my $w = $w01; $w <= $w11; $w += $d) {
    my $x1 = $x + int(0.5 + $rx * sin($w));
    my $y1 = $y + int(0.5 + $ry * cos($w));
    plot($x1, $y1);
  }
  if ($pie) {
    plot($x, $y);
  }
}

# Draw an ellipse.
# x   coordinate center
# y   coordinate center
# rx  coordinate radius
# ry  coordinate radius
sub ellipse {
  my ($x, $y, $rx, $ry) = @_;
  ellipticArc($x, $y, $rx, $ry, 0.0, 1.0, 30, 0);
}

# Return the width of a text.
# t  some text.
sub textW {
  my $t = shift;
  return length($t) * $fontWidth[$fontsize];
}

# Return the height of a character.
sub textH {
  return $fontHeight[$fontsize];
}

# Move the text cursor position.
# Implicitly switches to alpha mode.
# x text position
# y text position
sub home {
  my ($x, $y) = @_;
  plotAlpha;
  plot($x * textW('x'), ($y + 1) * textH);
}

# Write text at the current position.
# Optionally move.
# t  some text.
# m  0: don't move
#    1: move to end of text
#    2: move to next line
sub text {
  my ($t, $m) = @_;
  if ($plotmode == PLOTMODEALPHA) {
    my $s = getStyle;
    my $tl = textW($t);
    $t =~ s/ /&nbsp;/g;
    spool(qq(<text x="$lastX" y="$lastY" textLength="$tl" $s>$t</text>));
    if ($m == TOEND) {
      $lastX += $tl;
    }
    if ($m == NEWLINE) {
      $lastY += textH;
    }
  }
}

# Draw a labeled coordinate axis.
sub axis {
  my ($x, $y, $w, $pos, $u0, $u1, $u2, $uf, $uj) = @_;
  my $left = $pos == 2;
  my $botm = $pos == 0;
  my $horz = $pos < 2;
  my $tickH = 7;
  plotLine;
  plot($x, $y);
  my $xy1;
  if ($horz) {
    plot($x + $w-1, $y);
    $xy1 = $x;
  }
  else {
    plot($x, $y + $w-1);
    $xy1 = $y + $w-1;
  }
  my $u11 = $u1 * 1.005;
  my $du = $u1 - $u0;
  my $j = 0;
  for (my $u = $u0; $u <= $u11; $u += $u2) {
    if ($j % $uj == 0) {
      my $ufs = sprintf($uf, $u);
      plotLine;
      if ($horz) {
        plot($xy1, $y);
        plot($xy1, $y + ($botm ? -$tickH : $tickH));
      } else {
        plot($x, $xy1);
        plot($x + ($left ? $tickH : -$tickH), $xy1);
      }
      plotAlpha;
      if ($horz) {
        plot($xy1, $y + ($botm ? textH : -textH()/4));
      } else {
        plot($x + ($left ? -textW($ufs)-textW('x')/4 : textW('x')/4), $xy1);
      }
      text($ufs, NOMOVE);
    }
    my $dxy1 = $u2 * $w / $du;
    if ($horz) {
      $xy1 += $dxy1;
    } else {
      $xy1 -= $dxy1;
    }
    $j++;
  }
}

my $m_xwd = 0;
my $m_ywd = 0;
my $m_xd = 0;
my $m_yd = 0;
my $m_x0 = 0;
my $m_y0 = 0;
my $m_xw0 = 0;
my $m_yw0 = 0;

sub mapDef {
  my ($xw0, $yw0, $xw1, $yw1, $x0, $y0, $x1, $y1) = @_;
  $m_xwd = $xw1 - $xw0;
  $m_ywd = $yw1 - $yw0;
  $m_xd = $x1 - $x0;
  $m_yd = $y1 - $y0;
  $m_x0 = $x0;
  $m_y0 = $y0;
  $m_xw0 = $xw0;
  $m_yw0 = $yw0;
}

sub mapX {
  my $xw = shift;
  return ($xw-$m_xw0) / $m_xwd * $m_xd + $m_x0;
}

sub mapwX {
  my $x = shift;
  return ($x-$m_x0) / $m_xd * $m_xwd + $m_xw0;
}

sub mapY {
  my $yw = shift;
  #return ($yw-$m_yw0) / $m_ywd * $m_yd + $m_y0;
  return ($m_y0 + $m_yd - 1) - (($yw-$m_yw0) / $m_ywd * $m_yd);
}

sub mapwY {
  my $y = shift;
  #return ($y-$m_y0) / $m_yd * $m_ywd + $m_yw0;
  return ($m_y0 + $m_yd - 1 - $y) / $m_yd * $m_ywd + $m_yw0;
}

1;
