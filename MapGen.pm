# $Id: MapGen.pm,v 1.42 2005/04/01 14:04:46 jettero Exp $
# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen;

use strict;
use AutoLoader;
use Carp;
use Data::Dumper; $Data::Dumper::Indent = 1; $Data::Dumper::SortKeys = 1;

our $VERSION = "0.19";
our $AUTOLOAD;

# known_opts {{{
our %known_opts = (
    generator              => "Basic",
    visualization          => "Text",
    bounding_box           => "50x50",
    tile_size              => "3 ft",
    cell_size              => "20x20",

    num_rooms              => "1d4+1",
    min_room_size          => "2x2",
    max_room_size          => "7x7",

    sparseness             => 10,
          same_way_percent => 90,
         same_node_percent => 30,
    remove_deadend_percent => 60,

      open_room_corridor_door_percent     => { door => 95, secret =>  2, stuck => 25, locked => 50 },
    closed_room_corridor_door_percent     => { door =>  5, secret => 95, stuck => 10, locked => 30 },
      open_corridor_corridor_door_percent => { door =>  1, secret => 10, stuck => 25, locked => 50 },
    closed_corridor_corridor_door_percent => { door =>  1, secret => 95, stuck => 10, locked => 30 },
);
# }}}

1;

# AUTOLOAD {{{
sub AUTOLOAD {
    my $this = shift;
    my $sub  = $AUTOLOAD;

    if( $sub =~ m/MapGen\:\:set_([\w\d\_]+)$/ ) {
        delete $this->{objs}{$1} if $this->{objs}{$1};
        $this->{$1} = shift;

        croak "ERROR: set_$1() doesn't let you unset a setting.  Value undefined..." unless defined $this->{$1};

        if( my $e = $this->check_opts ) { croak $e }

        return;
    } elsif( $sub =~ m/MapGen\:\:add_(\w+)_plugin$/ ) {
        my $type = $1;
        my $plug = shift;
    }

    croak "ERROR: function $sub() not found";
}
sub DESTROY {}
# }}}
# check_opts {{{
sub check_opts {
    my $this = shift;
    my @e    = ();

    for my $k ( keys %$this ) {
        unless( exists $known_opts{$k} ) {
            next if $k eq "objs";
            next if $k eq "_the_map";
            next if $k eq "_the_groups";

            push @e, "unrecognized option: '$k'";
        }
    }

    return "ERROR:\n\t" . join("\n\t", @e) . "\n" if @e;
    return;
}
# }}}
# new {{{
sub new {
    my $class = shift;
    my @opts  = @_;
    my $opts  = ( (@opts == 1 and ref($opts[0]) eq "HASH") ? $opts[0] : {@opts} );
    my $this  = bless $opts, $class;

    if( my $e = $this->check_opts ) { croak $e }

    for my $k (keys %known_opts) {
        $this->{$k} = $known_opts{$k} unless $this->{$k};
    }

    return $this;
}
# }}}

# save_map {{{
sub save_map {
    my $this     = shift;
    my $filename = shift;

    $this->{_the_map}->disconnect_map;

    my @keys = keys %$this;

    open _SAVE, ">$filename" or die "couldn't open $filename for write: $!";
    print _SAVE Data::Dumper->Dump([map($this->{$_}, @keys)], [map("\$this\-\>{$_}", @keys)]);
    close _SAVE;

    $this->{_the_map}->interconnect_map;
}
# }}}
# load_map {{{
sub load_map {
    my $this     = shift;
    my $filename = shift;

    open _LOAD, "$filename" or die "couldn't open $filename for read: $!";
    my $entire_file = join("", <_LOAD>);
    close _LOAD;

    eval $entire_file;
    die "ERROR while evaluating saved map: $@" if $@;

    require Games::RolePlay::MapGen::Tools; # This would already be loaded if we were the blessed ref that did the saving
    $this->{_the_map}->interconnect_map;    # bit it wouldn't be loaded otherwise!
}
# }}}
# generate {{{
sub generate {
    my $this = shift;
    my $err;

    __MADE_GEN_OBJ:
    if( my $gen = $this->{objs}{generator} ) {

        ($this->{_the_map}, $this->{_the_groups}) = $gen->go( @_ );

        return;

    } else {
        die "ERROR: problem creating new generator object" if $err;
    }

    eval qq( require $this->{generator} ); 
    if( $@ ) {
        eval qq( require Games::RolePlay::MapGen::Generator::$this->{generator} );
        if( $@ ) {
            croak "ERROR locating generator module:\n\t$@\n " if $@;
        }

        $this->{generator} = "Games::RolePlay::MapGen::Generator::$this->{generator}";
    }

    my $obj;
    my @opts = map(($_=>$this->{$_}), grep {defined $this->{$_}} keys %$this);

    eval qq( \$obj = new $this->{generator} (\@opts); );
    if( $@ ) {
        die   "ERROR generating generator:\n\t$@\n " if $@ =~ m/ERROR/;
        croak "ERROR generating generator:\n\t$@\n " if $@;
    }

    $this->{objs}{generator} = $obj;
    $err = 1;
    goto __MADE_GEN_OBJ;
}
# }}}
# visualize {{{
sub visualize {
    my $this = shift;
    my $err;

    __MADE_VIS_OBJ:
    if( my $vis = $this->{objs}{visualization} ) {

        $vis->go( _the_map => $this->{_the_map}, _the_groups => $this->{_the_groups}, (@_==1 ? (fname=>$_[0]) : @_) );

        return;

    } else {
        die "problem creating new visualization object" if $err;
    }

    eval qq( require $this->{visualization} );
    if( $@ ) {
        eval qq( require Games::RolePlay::MapGen::Visualization::$this->{visualization});
        if( $@ ) {
            croak "ERROR locating visualization module:\n\t$@\n " if $@;
        }

        $this->{visualization} = "Games::RolePlay::MapGen::Visualization::$this->{visualization}";

    }

    my $obj;
    my @opts = map(($_=>$this->{$_}), grep {defined $this->{$_}} keys %$this);

    eval qq( \$obj = new $this->{visualization} (\@opts); );
    if( $@ ) {
        die   "ERROR generating visualization:\n\t$@\n " if $@ =~ m/ERROR/;
        croak "ERROR generating visualization:\n\t$@\n " if $@;
    }

    $this->{objs}{visualization} = $obj;
    $err = 1;
    goto __MADE_VIS_OBJ;
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen - The base object for generating dungeons and maps

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    $map->set_generator("Basic");             # This is actually the default generator,
    $map->add_generator_plugin("BasicDoors"); # however, you must add the doors.
    generate $map("map.txt");                 # It'll generate a text map by default.

    $map->set_visualization( "BasicImage" );  # But a graphical map is probably more useful.
    generate $map("map.png");

=head1 AUTHOR

Jettero Heller <japh@voltar-confed.org>

Jet is using this software in his own projects...
If you find bugs, please please please let him know. :)

Actually, let him know if you find it handy at all.
Half the fun of releasing this stuff is knowing 
that people use it.

=head1 Special Thanks to Jamis Buck

I emailed Jamis and asked for permission to duplicate the text of portions
of his "Random Dungeon Design: The Secret Workings of Jamis Buck's Dungeon
Generator" document (http://www.aarg.net/~minam/dungeon_design.html) and he
was cool with that.

Really, without his work, I never would have written this module!

=head1 COPYRIGHT

GPL!  I included a gpl.txt for your reading enjoyment.

Though, additionally, I will say that I'll be tickled if you were to
include this package in any commercial endeavor.  Also, any thoughts to
the effect that using this module will somehow make your commercial
package GPL should be washed away.

I hereby release you from any such silly conditions.

This package and any modifications you make to it must remain GPL.  Any
programs you (or your company) write shall remain yours (and under
whatever copyright you choose) even if you use this package's intended
and/or exported interfaces in them.

=head1 SEE ALSO

perl(1)

=cut
