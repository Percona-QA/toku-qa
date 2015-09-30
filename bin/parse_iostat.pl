#!/usr/bin/perl -w

sub average {
    @_ == 1 or die ('Sub usage: $average = average(\@array);');
    my ($array_ref) = @_;
    my $sum;
    my $count = scalar @$array_ref;
    foreach (@$array_ref) { $sum += $_; }
    return $sum / $count;
}

sub parse_file {
    my $input_file = shift;
    
    my $line = "";
    my $good_lines = 0;
    my $bad_lines = 0;
    
    my $num_measurements = 0;
    
    my $total_read_per_sec = 0;
    my $total_write_per_sec = 0;
    
    my $avg_read_per_sec = -1;
    my $avg_write_per_sec = -1;

    
    my $file_state = "unknown";

    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ "Device:") {
            $file_state = "started";
            $num_measurements++;
        } elsif ($file_state eq "started") {
            if ($line ne "") {
                #Device:         rrqm/s   wrqm/s   r/s   w/s    rMB/s    wMB/s avgrq-sz avgqu-sz   await  svctm  %util
                #cciss/c0d0        0.44     2.74 24.94 41.37     1.19     5.83   216.78     1.04   15.69   0.54   3.60
                #cciss/c0d0p1      0.06     2.49  0.30  1.42     0.00     0.02    23.11     0.01    5.71   1.09   0.19
                #cciss/c0d0p2      0.00     0.02  0.24  0.61     0.00     0.04    97.53     0.01    7.71   1.52   0.13
                #cciss/c0d0p3      0.00     0.00  0.00  0.00     0.00     0.00    59.76     0.00    4.93   4.56   0.00
                #cciss/c0d0p4      0.00     0.00  0.00  0.00     0.00     0.00     3.00     0.00    4.00   4.00   0.00
                #cciss/c0d0p5      0.38     0.23 24.39 39.34     1.19     5.77   223.61     1.02   16.07   0.54   3.47
                #sda               0.00     0.00  0.00  0.00     0.00     0.00    17.31     0.00    0.29   0.29   0.00
                #sdb               0.04   153.48  8.80  5.59     0.33     0.62   134.91     3.54  245.82   2.02   2.91
                #
                #Device:         rrqm/s   wrqm/s     r/s     w/s    rMB/s    wMB/s avgrq-sz avgqu-sz   await  svctm  %util
                #sdb               0.00     0.00    0.00    0.00     0.00     0.00    29.53     0.00    0.25   0.15   0.00
                #sdc               0.02   164.50   16.46    8.02     0.80     0.67   123.62     1.47   60.01   1.61   3.94
                #sda               1.04    22.89   21.98  105.32     1.09    10.33   183.68     1.39   10.92   0.42   5.35

                my @line_values = split(/ +/, $line);
    
                my $this_device = $line_values[0];
                my $this_read_per_sec = $line_values[3];
                my $this_write_per_sec = $line_values[4];
    
                if (($this_device =~ "sd") || ($this_device =~ "cciss/c0d0\$")) {
                    $total_read_per_sec += $this_read_per_sec;
                    $total_write_per_sec += $this_write_per_sec;
                } elsif ($this_device =~ "cciss/c0d0") {    
                    # do nothing, these are expected
                } else {
                    print $this_device . "/n";
                }
            }
        } else {
            $bad_lines++;
            # bad line, output info
            #print "BAD LINE FOUND: $line\n";
        }
    }

    if ($num_measurements > 0) {
        $avg_read_per_sec = $total_read_per_sec / $num_measurements;
        $avg_write_per_sec = $total_write_per_sec / $num_measurements;
    }

    printf("arps %.2f awps %.2f\n", $avg_read_per_sec, $avg_write_per_sec);

    close inFILE;
}


if (@ARGV == 0) {
    print "usage: parse_iostat.pl <input-file-name>\n";
    exit;
}

$file_name = $ARGV[0];

parse_file($file_name);
