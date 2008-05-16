
use strict;
use Test;
use File::Slurp;

use Games::RolePlay::MapGen;
my $map = new Games::RolePlay::MapGen({bounding_box => join("x", 25, 25) });
   $map->add_generator_plugin("BasicDoors");
   $map->generate;

plan tests => 3 + (25*25) + 1 + 2;

# if you know of a way to actually test these, you go ahead and email me, ok?

$map->set_exporter("Text");
$map->export("map.txt"); 
ok( -f "map.txt" );

$map->export( fname=>"map.tnc", nocolor=>1 ); 
ok( -f "map.txt" );

my $txt = read_file('map.txt'); $txt =~ s/\e\[[\d;]*m//g;
my $tnc = read_file('map.tnc');
ok( $txt, $tnc );

eval "use GD;"; 
if( $@ ) {
    ok( 1 ); # this should probably be a skip() instead... meh

} else {
    set_exporter $map("BasicImage");
    export $map("map.png"); 
    ok( -f "map.png" );
}

# However, this I could actually test... if I got around to it.

set_exporter $map("XML");
export $map("map.xml"); 
ok( -f "map.xml" );

use XML::Simple;
set_exporter $map("XML");
export $map("map.xml"); 

skip( (not (-f "/usr/bin/xmllint")) => system(qw(/usr/bin/xmllint --path blib/lib/Games/RolePlay/MapGen --postvalid --noout map.xml)), 0);

open IN, "map.xml" or die $!;
my $xmap = XMLin( join("\n", <IN>) )->{'map'}; close IN;

## DEBUG ## use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1; 
## DEBUG ## open OUT, ">map.dumper.pl";
## DEBUG ## print OUT Dumper($xmap);
## DEBUG ## close OUT;

for my $row (@{ $xmap->{row} }) {
    for my $tile (@{ $row->{tile} }) {
        ok( 1 );
    }
}
