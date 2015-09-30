#!/usr/bin/perl -w

my $commandLineArgs = $#ARGV + 1;

if ($commandLineArgs == 0) {
    print "usage: pct-diff.pl <infile1> <infile2>\n";
    exit;
}

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

open (inFILE1, "$file1") || die "cannot open file for reading $!";
my @lines1 = <inFILE1>;
close inFILE1;

open (inFILE2, "$file2") || die "cannot open file for reading $!";
my @lines2 = <inFILE2>;
close inFILE2;

print "*******************************************************************************************************\n";
print "comparing $file1\n";
print "       to $file2\n";
print "*******************************************************************************************************\n";

foreach my $l1 (@lines1) {
    chomp($l1);
    my $l2 = shift @lines2;
    chomp($l2);
    
    my $tps1 = 0;
    my $tps2 = 0;

    my @array1 = split /\s+/, $l1;
    my @array2 = split /\s+/, $l2;
    
    $tps1 = $array1[3];
    $tps2 = $array2[3];
        
    my $string_pct_diff = "";

    print "$array1[4]" . " | $tps1 | $tps2 | ";
    
    if (($tps1 > 0) && ($tps2 > 0)) {
        my $value_pct_diff = (($tps2 - $tps1) / $tps1) * 100;
        my $tens_pct_diff = int(abs($value_pct_diff));
        $string_pct_diff = sprintf("%.2f", $value_pct_diff) . "% | ";
        if ($value_pct_diff < 0) {
            $string_pct_diff .= "  " . '-' x $tens_pct_diff;
        } else {
            $string_pct_diff .= "  " . '+' x $tens_pct_diff;
        }
    } else {
        $string_pct_diff = " *** UNKNOWN ***";
    }
    
    print "$string_pct_diff" . "\n";
}
