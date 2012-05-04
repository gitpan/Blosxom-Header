use strict;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::Base;
use Blosxom::Header;

plan tests => 2 + 2 * blocks;

{
    package blosxom;
    our $static_entries = 0;
    our $header = {};
    our $output;
}

my $plugin = 'conditional_get';
require "$Bin/$plugin";

can_ok $plugin, qw/start last/;
ok $plugin->start;

filters {
    input    => 'yaml',
    expected => 'yaml',
};

run {
    my $block    = shift;
    my $input    = $block->input;
    my $expected = $block->expected;
    
    # initial configuration
    local $blosxom::output = $input->{output};
    local %ENV = %{ $input->{env} };
    tie my %header, 'Blosxom::Header';
    %header = %{ $input->{header} };

    $plugin->last;
    
    is_deeply $blosxom::header, $expected->{header};
    is        $blosxom::output, $expected->{output};
};

__DATA__
===
--- input
header:
    -type: text/html
env:
    REQUEST_METHOD: GET
output: abcdj
--- expected
header:
    -type: text/html
output: abcdj
===
--- input
header:
    -type: text/html
    -etag: Foo
env:
    REQUEST_METHOD:     GET
    HTTP_IF_NONE_MATCH: Foo
output: abcdj
--- expected
header:
    -type:   ''
    -etag:   Foo
    Status: 304 Not Modified
output: ''
===
--- input
header:
    -type:          text/html
    -last-modified: Wed, 23 Sep 2009 13:36:33 GMT
env:
    REQUEST_METHOD:         GET
    HTTP_IF_MODIFIED_SINCE: Wed, 23 Sep 2009 13:36:33 GMT
output: abcdj
--- expected
header:
    -type:          ''
    -last-modified: Wed, 23 Sep 2009 13:36:33 GMT
    Status:        304 Not Modified
output: ''
===
--- input
header:
    -type:          text/html
    -last-modified: Wed, 23 Sep 2009 13:36:33 GMT
env:
    REQUEST_METHOD:         GET
    HTTP_IF_MODIFIED_SINCE: Wed, 23 Sep 2009 13:36:32 GMT
output: abcdj
--- expected
header:
    -type:          text/html
    -last-modified: Wed, 23 Sep 2009 13:36:33 GMT
output: abcdj
===
--- input
header:
    -type:          text/html
    -last-modified: Wed, 23 Sep 2009 13:36:33 GMT
env:
    REQUEST_METHOD:         GET
    HTTP_IF_MODIFIED_SINCE: Wed, 23 Sep 2009 13:36:33 GMT; length=2
output: abcdj
--- expected
header:
    -type:          ''
    -last-modified: Wed, 23 Sep 2009 13:36:33 GMT
    Status:        304 Not Modified
output: ''
===
--- input
header:
    -type: text/html
    -etag: Foo
env:
    REQUEST_METHOD:     POST 
    HTTP_IF_NONE_MATCH: Foo
output: abcdj
--- expected
header:
    -type: text/html
    -etag: Foo
output: abcdj
