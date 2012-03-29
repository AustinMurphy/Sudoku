#!/usr/bin/perl
#
# Written by Austin Murphy, October 2010
#
# Released to the Public Domain
#

#
# take a sudoku grid as input and output the solution 
# 

# TODO:  
#   - correctness test
#   - 2nd level logic for "hard" puzzles
#   - output messages in standard format
#   ?
#

use strict;

#
# Global vars
#

my $show_how = '0';

# 2D matrix
#  row (0-8), col (0-8)
my @startgrid;

# 2D matrix
#  row (0-8), col (0-8)
my @solution;

# 3D matrix
#  row (1-9), col (1-9), digit (1-9)
#  1 - possible, 0 - not possible to have this digit at this location
my @possib;  




#
#  subroutines
#

sub init_grids {

  #
  # Load grid (comma separated columns, newline separated lines)
  #
  while (<>) {
    chomp;
    push @startgrid, [ split(/,/) ];
  }
  
  # 
  # start with blank solution grid
  #
  for my $row ( 0 .. 8 ) {
    for my $col ( 0 .. 8 ) {
     $solution[$row][$col] = ' ';
    }
  }
  
  #
  # build 3D possibility matrix
  #
  # start with "anything is possible"
  for my $row ( 1 .. 9 ) {
    for my $col ( 1 .. 9 ) {
      for my $dig ( 1 .. 9 ) {
        $possib[$row][$col][$dig] = '1';
      }
    }
  }

}

sub markassolved {
  my $inrow = shift;
  my $incol = shift;
  my $indig = shift;
  my $comment = shift;

  if ( $show_how == '0' ) {
    if ( $comment !~ /GIVEN/ ) {
      print $comment;
      print "Solved  -- Digit: $indig in Row: $inrow, Col: $incol \n";
    }
  }

  # mark this digit in all elements in this row as not possible
  for my $col ( 1 .. 9 ) {
    $possib[$inrow][$col][$indig] = '0';
  }
  
  # mark this digit in all elements in this column as not possible
  for my $row ( 1 .. 9 ) {
    $possib[$row][$incol][$indig] = '0';
  }

  # mark this digit in all elements in this 3x3 box as not possible
  use integer;
  my $startrow = 1 + 3 * (($inrow - 1 ) / 3);
  my $endrow = $startrow + 2; 
  my $startcol = 1 + 3 * (($incol - 1 ) / 3);
  my $endcol = $startcol + 2; 
  #print "input row: $inrow , input col: $incol \n";
  #print "marking off rows: $startrow - $endrow, cols: $startcol - $endcol \n";
  for my $row ( $startrow .. $endrow ) {
    for my $col ( $startcol .. $endcol ) {
      $possib[$row][$col][$indig] = '0';
    }
  }

  # mark all other digits in this element impossible
  for my $dig ( 1 .. 9 ) {
    $possib[$inrow][$incol][$dig] = '0';
  } 

  # re-mark this digit in this element as possible 
  $possib[$inrow][$incol][$indig] = '1';

  #mark this digit in this location in the solution
  $solution[$inrow -1 ][$incol -1 ] = $indig;
}

#
# show the possibilites for one digit
# 

sub show_possib_layer {
  my $indig = shift;

  print "possibilities for digit: $indig \n";
  for my $row ( 1 .. 9 ) {
    if ( $row % 3 == 1 ) {
      print "+-------+-------+-------+\n";
    }
    for my $col ( 1 .. 9 ) {
      if ( $col % 3 == 1 ) {
        print "| ";
      }
      if ( $possib[$row][$col][$indig] == '0' ) {
        print "  ";
      } else {
        print "$indig ";
      }
    }
    print "|\n";
  }
  print "+-------+-------+-------+\n";
  
}

sub show_all_possib {
  print "remaining possibilities for each element: \n";
  print "++-------+-------+-------++-------+-------+-------++-------+-------+-------++\n";
  for my $row ( 1 .. 9 ) {
    if ( $row % 3 == 1 ) {
      print "++-------+-------+-------++-------+-------+-------++-------+-------+-------++\n";
    }
    # 1/3rds
    for my $startdig ( 1, 4, 7 ) {
      print "|";
      for my $col ( 1 .. 9 ) {
        if ( $col % 3 == 1 ) {
          print "|";
        }
        print " ";
        for my $dig ( $startdig .. $startdig+2 ) {
          if ( $possib[$row][$col][$dig] == '0' ) {
            print "  ";
          } else {
            print "$dig ";
          }
        }
        print "|";
      }
      print "|\n";
    }
    print "++-------+-------+-------++-------+-------+-------++-------+-------+-------++\n";
  }
  print "++-------+-------+-------++-------+-------+-------++-------+-------+-------++\n";

}

sub print_grid {
  my @grid = @_;

  for my $row ( 0 .. 8 ) {
    if ( $row % 3 == 0 ) {
      print "+-------+-------+-------+\n";
    }
    for my $col ( 0 .. 8 ) {
      if ( $col % 3 == 0 ) {
        print "| ";
      }
      print "$grid[$row][$col] ";
    }
    print "|\n";
  }
  print "+-------+-------+-------+\n";

}


# mark off impossibilities based on starting numbers

sub process_givens {
  for my $row ( 1 .. 9 ) {
    for my $col ( 1 .. 9 ) {
  
      my $digit = $startgrid[$row - 1][$col - 1];
  
      if ( $digit != '0' ) {
        markassolved( $row, $col, $digit, "GIVEN  : " );
      }
  
    }
  }
} 


#
# search for solutions 
# 

# HiddenSingle - Row
# WHY: each row/col/box MUST have one of each digit
sub search_row {
  for my $dig ( 1 .. 9 ) {
    # check if a digit has only one possibility in a given row
    for my $row ( 1 .. 9 ) {
      my $rowsum = 0;
      for my $col ( 1 .. 9 ) {
        $rowsum += $possib[$row][$col][$dig];
      }
      if ( $rowsum == 1 ) {
        for my $col ( 1 .. 9 ) {
          if ( $possib[$row][$col][$dig] == '1' && $solution[$row-1][$col-1] == ' ' ) {
            markassolved( $row, $col, $dig, "ROW    : " );
            return 1;
          }
        }
      }
    }
  }
  # no row solution found
  return 0;
}

# HiddenSingle - Col
sub search_col {
  for my $dig ( 1 .. 9 ) {
    # check if a digit has only one possibility in a given col
    for my $col ( 1 .. 9 ) {
      my $colsum = 0;
      for my $row ( 1 .. 9 ) {
        $colsum += $possib[$row][$col][$dig];
      }
      if ( $colsum == 1 ) {
        for my $row ( 1 .. 9 ) {
          if ( $possib[$row][$col][$dig] == '1' && $solution[$row-1][$col-1] == ' ' ) {
            markassolved( $row, $col, $dig, "COL    : " );
            return 1;
          }
        }
      }
    }
  }
  # no col solution found
  return 0;
}

# HiddenSingle - Box
sub search_box {
  for my $dig ( 1 .. 9 ) {
    # check if a digit has only one possibility in a given box
    for my $box ( 1 .. 9 ) {
      
      use integer;
      my $startrow = 1 + 3 * ( ( $box - 1 ) / 3 );
      my $endrow = $startrow + 2;

      my $startcol = 1 + 3 * ( ( $box - 1 ) % 3 );
      my $endcol = $startcol + 2;

      my $boxsum = 0;
      for my $row ( $startrow .. $endrow ) {
        for my $col ( $startcol .. $endcol ) {
          $boxsum += $possib[$row][$col][$dig];
        }
      }
      if ( $boxsum == 1 ) {
        for my $row ( $startrow .. $endrow ) {
          for my $col ( $startcol .. $endcol ) {
            if ( $possib[$row][$col][$dig] == 1 && $solution[$row-1][$col-1] == ' ' ) {
              markassolved( $row, $col, $dig, "BOX    : " );
              return 1;
            }
          }
        }
      }
    }
  }
  # no box solution found
  return 0;
}

# NakedSingle 
sub search_naked_single {
  # check if all other digits at this location have been eliminated
  # WHY: each location can only have one digit
  for my $row ( 1 .. 9 ) {
    for my $col ( 1 .. 9 ) {

      # check to see if this location has been solved yet
      if ( $solution[$row-1][$col-1] == ' ' ) {
        my $sum = 0;
        # check how many possibilities remain
        for my $dig ( 1 .. 9 ) {
          $sum += $possib[$row][$col][$dig];
        }
        # 1 possiblity means we can mark it as solved
        if ( $sum == 1 ) {
          for my $dig ( 1 .. 9 ) {
            if ( $possib[$row][$col][$dig] == '1' ) {
              markassolved( $row, $col, $dig, "DIGIT  : " );
              return 1;
            }
          }
        }
      }

    }
  }
  # no digit solution found
  return 0;
}

#
# Check if puzzle is completed
#
sub check_complete {
  for my $row ( 0 .. 8 ) {
    for my $col ( 0 .. 8 ) {
      if ( $solution[$row][$col] == ' ' ) {
        return 1;
      }
    }
  }
  return 0;
}

#
#  solve loop
#
sub simple_solve {
  my $keep_trying=1;
  
  while ( $keep_trying ) {
  
    if ( search_row() == '0' && search_col() == '0' && search_box() == '0' && search_naked_single() == '0' ) {
      $keep_trying=0;
    } 

  }
  
}

#
# END subroutines
#


#
#  do stuff
#

init_grids() ;

print "\n";
print " Starting Grid: \n";
print "\n";
print_grid( @startgrid );
print "\n";


process_givens() ;


simple_solve() ;


if ( check_complete() == '0' ) {
  print "SOLVED!!\n";
} else {
  print "\nIncomplete. Sorry.  \n";

  if ( $show_how == '0' ) {
    print "\n";
    show_all_possib();
    print "\n";
  }

}


print "\n";
print " Solution Grid: \n";
print "\n";
print_grid( @solution );
print "\n";


