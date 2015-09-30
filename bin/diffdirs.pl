#!/usr/bin/perl

#
# pdiff - diff directories with
# user/group and permissions checked
#
# 2008 - Mike Golvach - eggi@comcast.net
#
# Creative Commons Attribution-Noncommercial-Share Alike 3.0 United States License
#

if ($#ARGV != 1) {
 print "Usage: $0 dir1 dir2\n";
 exit;
}

$firstdir=$ARGV[0];
$seconddir=$ARGV[1];

@firstfiles=`ls -l $firstdir|grep -v total`;
@secondfiles=`ls -l $seconddir|grep -v total`;
@file1 = ();
@file2 = ();

foreach $firstbit (@firstfiles) {
 @firstparts = split(/  * */, $firstbit);
 @perms = split(//, $firstparts[0]);
 chomp(@perms);
 @user = ($perms[1], $perms[2], $perms[3]);
 @group = ($perms[4], $perms[5], $perms[6]);
 @other = ($perms[7], $perms[8], $perms[9]);
 $ucounter = 0;
 $gcounter = 0;
 $ocounter = 0;
 $majordiff = 0;
 foreach $perm (@user) {
  if ($perm eq "r") {
   $ucounter += 4;
  } elsif ($perm eq "w") {
   $ucounter += 2;
  } elsif ($perm eq "x") {
   $ucounter += 1;
  } elsif ($perm eq "s") {
   $ucounter += 1;
   $majordiff += 4;
  }
 }
 foreach $perm (@group) {
  if ($perm eq "r") {
   $gcounter += 4;
  } elsif ($perm eq "w") {
   $gcounter += 2;
  } elsif ($perm eq "x") {
   $gcounter += 1;
  } elsif ($perm eq "s") {
   $gcounter += 1;
   $majordiff += 2;
  }
 }
 foreach $perm (@other) {
  if ($perm eq "r") {
   $ocounter += 4;
  } elsif ($perm eq "w") {
   $ocounter += 2;
  } elsif ($perm eq "x") {
   $ocounter += 1;
  } elsif ($perm eq "t") {
   $ocounter += 1;
   $majordiff += 1;
  }
 }
 @permissions = ($majordiff, $ucounter, $gcounter, $ocounter);
 $permissions = join("", @permissions);
# print "$permissions $firstparts[8]";
 chomp($firstparts[8]);
 push(@file1, "$permissions $firstparts[8]---$firstparts[2] $firstparts[3]");
}
foreach $firstbit (@secondfiles) {
 @firstparts = split(/  * */, $firstbit);
 @perms = split(//, $firstparts[0]);
 chomp(@perms);
 @user = ($perms[1], $perms[2], $perms[3]);
 @group = ($perms[4], $perms[5], $perms[6]);
 @other = ($perms[7], $perms[8], $perms[9]);
 $ucounter = 0;
 $gcounter = 0;
 $ocounter = 0;
 $majordiff = 0;
 foreach $perm (@user) {
  if ($perm eq "r") {
   $ucounter += 4;
  } elsif ($perm eq "w") {
   $ucounter += 2;
  } elsif ($perm eq "x") {
   $ucounter += 1;
  } elsif ($perm eq "s") {
   $ucounter += 1;
   $majordiff += 4;
  }
 }
 foreach $perm (@group) {
  if ($perm eq "r") {
   $gcounter += 4;
  } elsif ($perm eq "w") {
   $gcounter += 2;
  } elsif ($perm eq "x") {
   $gcounter += 1;
  } elsif ($perm eq "s") {
   $gcounter += 1;
   $majordiff += 2;
  }
 }
 foreach $perm (@other) {
  if ($perm eq "r") {
   $ocounter += 4;
  } elsif ($perm eq "w") {
   $ocounter += 2;
  } elsif ($perm eq "x") {
   $ocounter += 1;
  } elsif ($perm eq "t") {
   $ocounter += 1;
   $majordiff += 1;
  }
 }
 @permissions = ($majordiff, $ucounter, $gcounter, $ocounter);
 $permissions = join("", @permissions);
# print "$permissions $firstparts[8]";
 chomp($firstparts[8]);
 push(@file2, "$permissions $firstparts[8]---$firstparts[2] $firstparts[3]");
}

$file1count = @file1;
$file2count = @file2;

if ( $file1count > $file2count ) {
 $filecount = $file1count;
} else {
 $filecount = $file2count;
} 

$indexer = 0;
while ( $indexer < $filecount ) {
 chomp($file1[$indexer]);
 chomp($file2[$indexer]);
 printf("%-40s%s\n", $file1[$indexer],$file2[$indexer]);
 $indexer++;
}
