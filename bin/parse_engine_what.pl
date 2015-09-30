#!/usr/bin/perl -w

use Date::Parse;

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
    my $search_string = shift;
    my $parse_type = shift;
    
    my $line = "";
    
    my $benchmark_begin_epoch=-1;
    my $last_found_epoch=0;
    my $lines_found=0;
    my $first_found_value="";
    my $last_found_value="";

    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if (($line =~ m/time now/) && ($benchmark_begin_epoch == -1)) {
            # get first instance of "time now" for benchmark begin epoch
            # time now | Sun Jan 27 09:14:23 2013 | Sun Jan 27 09:14:33 2013
            # starting time of the benchmark
            my @line_values = split(' \| ', $line);
            $benchmark_begin_epoch = str2time($line_values[2]);
        }
        
        if ($line =~ m/time now/) {
            # get first instance of "time now" for benchmark begin epoch
            # time now | Sun Jan 27 09:14:23 2013 | Sun Jan 27 09:14:33 2013
            # starting time of the benchmark
            my @line_values = split(' \| ', $line);
            $last_found_epoch = str2time($line_values[2]);
        }


        if ($line =~ m/$search_string/) {
            #print "$line\n";
            
            # found the string
            my @line_values = split(' \| ', $line);
            my $this_found_value_current = $line_values[2];
            my $this_found_value_past = $line_values[1];
            my $this_found_seconds = $last_found_epoch - $benchmark_begin_epoch;
            my $this_found_value_interval = $this_found_value_current - $this_found_value_past;
            if ($lines_found == 0) {
                $first_found_value = $this_found_value_past;
            }
            $last_found_value = $this_found_value_current;
            $lines_found++;
            
            if ($parse_type eq "interval") {
                print "$this_found_seconds $this_found_value_interval\n";
            }
        }
        
    }
    if ($parse_type eq "total") {
        my $this_total = $last_found_value - $first_found_value;
        my $this_total_interval = $last_found_epoch - $benchmark_begin_epoch;
        my $this_tps = $this_total / $this_total_interval;
        print "$this_total $this_total_interval $this_tps\n";
    }
    
    close inFILE;
}


my $num_args = $#ARGV + 1;
if ($num_args != 3) {
    print "usage: parse_engine_what.pl <input-file> <string> <interval|total>\n";
    exit;
}

my $parm_input_file = $ARGV[0];
my $parm_search_string = $ARGV[1];
my $parm_parse_type = $ARGV[2];

parse_file($parm_input_file,$parm_search_string,$parm_parse_type);
