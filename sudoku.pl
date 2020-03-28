use integer;
use Time::HiRes qw[gettimeofday tv_interval];

no strict;

@Sudoku;

sub readSudoku {
  @Sudoku = (<>);
  $Sudoku= join('',@Sudoku);
  $delim = '';
  $Sudoku =~  /([\,\;,\t,\ ])/ && do
  {
    $delim = $1;
  };
  if ($delim eq '') {
    @Sudoku = split(//,$Sudoku);
  } else {
    $Sudoku=~ s/[\r\n,\n,\,,\t,\ ]+/;/g;
    @Sudoku = split(/;/,$Sudoku);
  }
  #cleanup extra char at the end of file (eg. eol)
  $emptyToken = 1;
  while ($emptyToken)
  {
    $lastToken = pop(@Sudoku);
    if($lastToken =~ /[0-9]/)
    {
       push(@Sudoku, $lastToken);
       $emptyToken = 0;
    }
  }
  
  $SudokuSize = sqrt(scalar(@Sudoku));
  $SudokuNbCells = $SudokuSize * $SudokuSize;
  $SudokuMacroCellSize = sqrt($SudokuSize);
  our $SudokuNbMacroCells = $SudokuMacroCellSize * $SudokuMacroCellSize;
  die "Wrong Size" if  ( $SudokuNbCells != scalar(@Sudoku) ||  ($SudokuMacroCellSize * $SudokuMacroCellSize != $SudokuSize));
 }

sub printSudoku {
   for ($i = 0 ; $i < $SudokuNbCells; $i++) {
      if (length($Sudoku[$i]) == 1 ) {
        print "0$Sudoku[$i] ";
      } else {
        print "$Sudoku[$i] ";
      }
      print "$/" if !(($i+1) % $SudokuSize);
   }
   print "$/";
}

sub fillPossiblePos {
    my @LineSet;
    my @ColSet;
    my @MacroCellSet;
    my @ImpossiblePos;
     for (my $i = 0 ; $i < $SudokuNbCells; $i++) {
        my $line = $i / $SudokuSize;
        my $col  = $i % $SudokuSize;
        my $macroCell =  $SudokuMacroCellSize * ($line / $SudokuMacroCellSize) + $col / $SudokuMacroCellSize;
        my $bit = 2**$Sudoku[$i];
         $LineSet[$line] |= $bit;
         $ColSet[$col] |= $bit;
         $MacroCellSet[$macroCell] |= $bit;
    }
    for (my $i = 0 ; $i < $SudokuNbCells; $i++) {
        my$line = $i / $SudokuSize;
        my $col  = $i % $SudokuSize;
        my $macroCell =  $SudokuMacroCellSize * ($line / $SudokuMacroCellSize) + $col / $SudokuMacroCellSize;
        if  ($Sudoku[$i] == 0) {
          $PossiblePos[$i] = ~($LineSet[$line]  |  $ColSet[$col] | $MacroCellSet[$macroCell]);
        } else {
          $PossiblePos[$i] = 0;
        }
    }
    @PossiblePos;
}

sub Unique {
    my @unique;
        for (my $i = 1 ; $i <= $SudokuSize; $i++) {
        $unique[$i] = 2**$i;
    }
    @unique;
}

sub fillUnique{
    $changed = 0;
    for (my $i = 0 ; $i < $SudokuNbCells; $i++) {
       my $x = 0;
       my $count = 0;
       for (my $k = 1 ; $k <= $SudokuSize; $k++) {
         if ($PossiblePos[$i] & $Unique[$k]) {
           $x = $k;
           $count++;
          }
       }
       if ($count == 1) {
         $changed = 1;
         $Sudoku[$i] = $x;
         &fillPossiblePos;

       }
    }
  $changed;
}
sub fillUniqueInLine{
    $changed = 0;
    for (my $l = 0; $l < $SudokuSize; $l++) {
      for (my $k = 1 ; $k <= $SudokuSize; $k++) {
        my $count = 0;
        my $x = 0;
        for (my $c = 0; $c < $SudokuSize; $c++) {
          my $i = $l * $SudokuSize + $c;
          if ($PossiblePos[$i] & 2**$k) {
            $x = $i;
            $count++;
          }
        }
        if ($count == 1) {
           $changed = 1;
           $Sudoku[$x] = $k;
           &fillPossiblePos;
        }
      }
    }
  $changed;
}

sub fillUniqueInCol{
    $changed = 0;
    for (my $c = 0; $c < $SudokuSize; $c++) {
      for (my $k = 1 ; $k <= $SudokuSize; $k++) {
        my $count = 0;
        my $x = 0;
        for (my $l = 0; $l < $SudokuSize; $l++) {
          my $i = $l * $SudokuSize + $c;
          if ($PossiblePos[$i] & 2**$k) {
            $x = $i;
            $count++;
          }
        }
        if ($count == 1) {
           $changed = 1;
           $Sudoku[$x] = $k;
           &fillPossiblePos;
        }
      }
    }
  $changed;
}

sub fillUniqueInMacroCell{
    $changed = 0;
    for ( $L = 0; $L < $SudokuMacroCellSize; $L++) {
      for ( $C = 0; $C < $SudokuMacroCellSize; $C++) {
        for (my $k = 1 ; $k <= $SudokuSize; $k++) {
          my $count = 0;
          my $x = 0;
          for (my $l = $SudokuMacroCellSize * $L; $l < $SudokuMacroCellSize * ($L + 1); $l++) {
            for (my $c = $SudokuMacroCellSize * $C; $c < $SudokuMacroCellSize * ($C + 1); $c++) {
              my $i = $l * $SudokuSize + $c;
              if ($PossiblePos[$i] & 2**$k) {
                $x = $i;
                $count++;
              }
            }
          }
          if ($count == 1) {
            $changed = 1;
            $Sudoku[$x] = $k;
            &fillPossiblePos;
          }
        }
      }
    }
  $changed;
}

sub nbPossibilities {
  my $cell = shift @_;
  my $count = 0;
  for (my $k = 1 ; $k <= $SudokuSize; $k++) {
    if ($PossiblePos[$cell] & 2**$k) {
      $count++;
    }
  }
  $count;
}

sub findNextCell {
    my $cell = $SudokuNbCells;
    my $nbPossibilities = $SudokuSize;
    for (my $i = 0 ; $i < $SudokuNbCells; $i++) {
      if ($Sudoku[$i] == 0) {
         if ($cell == $SudokuNbCells) {
            $cell = $i;
         }
         my $nbiPossibilities = nbPossibilities($i);
         if ($nbiPossibilities < $nbPossibilities) {
           $cell = $i;
           $nbPossibilities = $nbiPossibilities;
         }
      }
    }
    $cell;
}

sub fillSudokuCell {
   my @savedUnique =  @Unique;
   my @savedPossiblePos = @PossiblePos;
   my @savedSudoku = @Sudoku;


   while (&fillUnique || &fillUniqueInLine || &fillUniqueInCol  || &fillUniqueInMacroCell) {}
   if (&findWithBruteForceSolver == 1) {
     return 1;
   }
   @Unique = @savedUnique;
   @PossiblePos = @savedPossiblePos;
   @Sudoku = @savedSudoku;
   return 0;
}

sub findWithBruteForceSolver {

   my $cell = findNextCell;
   if ($cell == $SudokuNbCells) {
     return 1;   # fin
   }
   for (my $k = 1 ; $k <= $SudokuSize; $k++) {
     $Sudoku[$cell] = 0;
     @PossiblePos = &fillPossiblePos;
     if ($PossiblePos[$cell] & 2**$k) {
        $Sudoku[$cell] = $k;
        @PossiblePos = &fillPossiblePos;
        if (&fillSudokuCell == 1) {
          return 1;
        }
     }
   }
   return 0;
}


readSudoku;
$t0 = [gettimeofday];
our ($seconds, $microseconds) = gettimeofday;

@Unique = &Unique;
@PossiblePos = &fillPossiblePos;

if (fillSudokuCell == 1) {
    printSudoku;
} else {
    print "This Sudoku is not solvable$/";
}
my $duration = tv_interval( $t0, [gettimeofday]);
printf "Execution time: %.6f seconds\n", $duration;
