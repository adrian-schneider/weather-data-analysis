use Statistics::Regression;

# Create regression object
my $reg = Statistics::Regression->new( "sample regression", [ "const", "someX", "someY" ] );

# Add data points
$reg->include( 2.0, [ 1.0, 3.0, -1.0 ] );
$reg->include( 1.0, [ 1.0, 5.0, 2.0 ] );
$reg->include( 20.0, [ 1.0, 31.0, 0.0 ] );
$reg->include( 15.0, [ 1.0, 11.0, 2.0 ] );

# Finally, print the result
$reg->print();
print "\n\n";

$reg = Statistics::Regression->new( "sample regression", [ "const", "someX" ] );

# Add data points
$reg->include( 3.0, [ 1.0, 1.05 ] );
$reg->include( 5.0, [ 1.0, 1.95 ] );
$reg->include( 7.0, [ 1.0, 3.05 ] );
$reg->include( 9.0, [ 1.0, 3.95 ] );

# Finally, print the result
my @lrth = $reg->theta();
print "y0   : " . $lrth[0] . "\n";
print "Dy/Dx: " . $lrth[1] . "\n";
#$reg->print();
