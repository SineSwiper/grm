# $Id: Perfect.pm,v 1.3 2005/03/25 17:01:33 jettero Exp $
# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator::Perfect;

use strict;
use Carp;
use base qw(Games::RolePlay::MapGen::Generator);
use Games::RolePlay::MapGen::Tools qw( _group _tile str_eval irange choice roll );

1;

# _create_tiles {{{
sub _create_tiles {
    my $this = shift;
    my $opts = shift;
    my @map  = ();

    for my $i (0 .. $opts->{y_size}-1) {
        my $a = [];

        for my $j (0 .. $opts->{x_size}-1) {
            push @$a, &_tile(x=>$j, y=>$i);
        }

        push @map, $a;
    }

    return @map;
}
# }}}
# _generate_perfect_maze {{{
sub _generate_perfect_maze {
    my $this = shift;
    my $opts = shift;
    my $map  = shift;

    # fully interconnect tiles (to ease perfect maze generation) {{{
    # This may be sloppy and wasteful, but it sure makes the maze alg easier to do.
    for my $i (0 .. $#$map) {
        my $jend = $#{ $map->[$i] };

        for my $j (0 .. $jend) {
            $map->[$i][$j]->{nb}{s} = $map->[$i+1][$j] unless $i == $#$map;
            $map->[$i][$j]->{nb}{n} = $map->[$i-1][$j] unless $i == 0;
            $map->[$i][$j]->{nb}{e} = $map->[$i][$j+1] unless $j == $jend;
            $map->[$i][$j]->{nb}{w} = $map->[$i][$j-1] unless $j == 0;
        }
    }
    # }}}
    # generate a perfect maze {{{
    my $tiles   = $opts->{y_size} * $opts->{x_size};
    my @dirs    = (qw(n s e w));
    my %opp     = ( n=>"s", s=>"n", e=>"w", w=>"e" );
    my $cur     = &choice(map(@$_, @$map));      
    my @togo    = @dirs;
    my $dir     = &choice(@togo);
    my @visited = ( $cur );

    $cur->{type} = "corridor";

    # open DEBUG, ">debug.log" or die $!;

    for(;;) {
        my $nex = $cur->{nb}{$dir};

        my $show = sub { my $n = shift; sprintf '(%2d, %2d)', $n->{x}, $n->{y} };

        # printf DEBUG '@visited=%3d; $cur=%s; $nex=%s;%s', int @visited, $show->($cur), $show->($nex);

        if( $nex and not $nex->{visited} ) {
            # print DEBUG " NEXT";

            $cur->{od}{$dir} = 1;

            $cur = $nex;
            $cur->{visited} = 1;
            push @visited, $cur;

            $cur->{od}{$opp{$dir}} = 1;
            $cur->{type} = 'corridor';

            @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
            $dir  = &choice(@togo) if &roll(1, 100) > $opts->{same_way_percent};
            # $opts->{same_way_percent} of the time, we won't change the direction

        } elsif( @togo ) {
            # print DEBUG " TOGO";

            $cur->{_pud}{$dir} = 1; # perfect's used dir

            # $opts->{same_node_percent} of the time, we try to use the same node
            if( @visited>1 and (&roll(1, 100) > $opts->{same_node_percent}) ) {
                # print DEBUG " SAME";
                # Pick a new node with a random direction that makes sense.
                $cur  = &choice(@visited);
                @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
                $dir  = &choice(@togo); # whenever we switch nodes, we pick a random direction though

            } else {
                # print DEBUG " DIFF";
                # Try a different direction at this same node.
                @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
                $dir  = &choice(@togo);
            }

        } else {
            # print DEBUG " DULL";
            # This node is so boring, we don't want to accidentally try it again
            @visited = grep {$_ != $cur} @visited;

            last unless @visited;

            # Pick a new node with a random direction that makes sense.
            $cur  = &choice(@visited);
            @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
            $dir  = &choice(@togo);
        }

        # print DEBUG "\n";
    }

    # }}}
    # clean-up interconnections {{{
    for my $i (0 .. $#$map) {
        my $jend = $#{ $map->[$i] };

        for my $j (0 .. $jend) {
            # Destroying the map won't destroy the tiles if they're self
            # referencing like this.  That's not a problem because of the
            # global destructor, *whew*; except that each new map generated,
            # until perl exits, would eat up more memory.  

            delete $map->[$i][$j]->{n}; # So we have to break the self-refs here.
        }
    }
    # }}}

}
# }}}

# _genmap {{{
sub _genmap {
    my $this   = shift;
    my $opts   = shift;
    my @map    = $this->_create_tiles( $opts );
    my @groups = ();

    $this->_generate_perfect_maze($opts, \@map);

    return (\@map, \@groups);
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Generator::Perfect - The perfect maze generator

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->set_generator( "Games::RolePlay::MapGen::Generator::Perfect" );

    generate $map;

=head1 DESCRIPTION

This generator creates a specified number of rooms inside a
bounding box and then adds the specified number of hallways
-- trying to get at least one per room.

Here is the URL to the steps listed below: http://www.aarg.net/~minam/dungeon_design.html

=head2 Jamis Buck's Dungeon Generator Algorithm

1. Start with a rectangular grid, x units wide and y units tall. Mark each cell in the grid
unvisited.

2. Pick a random cell in the grid and mark it visited. This is the current cell.

3. From the current cell, pick a random direction (north, south, east, or west). If (1) there is no
cell adjacent to the current cell in that direction, or (2) if the adjacent cell in that direction
has been visited, then that direction is invalid, and you must pick a different random direction. If
all directions are invalid, pick a different random visited cell in the grid and start this step
over again.

4. Let's call the cell in the chosen direction C. Create a corridor between the current cell and C,
and then make C the current cell. Mark C visited.

5. Repeat steps 3 and 4 until all cells in the grid have been visited.

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
