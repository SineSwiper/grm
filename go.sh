#!/bin/bash
# $Id: go.sh,v 1.13 2005/03/25 19:58:39 jettero Exp $
# vi:tw=0:

make || exit 1

perl -d:DProf -Iblib/lib -MGames::RolePlay::MapGen -e \
'my $map = new Games::RolePlay::MapGen({cell_size=>"20x20", num_rooms=>"3d8", bounding_box => 
    # "3x3"
    # "20x20"
    # "63x22"
    "50x37"
}); 

# set_generator $map("Games::RolePlay::MapGen::Generator::Perfect");

generate $map; 
generate $map; 

set_visualization $map("Games::RolePlay::MapGen::Visualization::BasicImage");
visualize $map("map.png");

set_visualization $map("Games::RolePlay::MapGen::Visualization::Text");
visualize $map("map.txt");

' || exit 1

xv map.png &


# perl -Iblib/lib -MExtUtils::Command::MM -e 'test_harness(0, "blib/lib", "blib/arch")' t/05*.t || exit 1


# perl -d:DProf -Iblib/lib -MGames::RolePlay::MapGen -e \
# 'my $map = new Games::RolePlay::MapGen({num_rooms=>"3d8", bounding_box => "63x22"}); 
# generate $map; visualize $map("map.txt");' || exit 1

# rm -vf script
# mkfifo script
# echo 030j61lrj:wqa > script &
# vi -s script map.txt
# rm -vf script

# cat map.txt || exit 1
