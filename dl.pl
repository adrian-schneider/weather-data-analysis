use strict;
use warnings;

use LWP::UserAgent();

my $url = 'http://ds.data.jma.go.jp/tcc/tcc/products/climate/climatview/list.php?&s=3&r=2&y=2019&m=10&e=0&k=1';
my $file = 'x.dat';

my $ua = LWP::UserAgent->new(timeout => 10);
# $ua->env_proxy;

my $response = $ua->get($url, ':content_file' => $file);

if ($response->is_success) {
    # print $response->decoded_content;
    print "done\n";
}
else {
    die $response->status_line;
}
