#!/usr/bin/perl -w

use Date::Parse;

sub parse_file {
    my $input_file = shift;
    my $search_string = shift;
    
    my $line = "";
    
    my $interval=0;
    my $value="";
    my $found_this_interval=0;

    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ m/time now/) {
            if ($interval != 0) {
                print "$interval $value\n";
                $found_this_interval=0;
            }
            $interval++;
        }
        
        if ($line =~ m/$search_string/) {
            #print "$line\n";
            
            # found the string
            my @line_values = split(' \| ', $line);
            $value = $line_values[2];
            $found_this_interval++;
            if ($found_this_interval > 1) {
                print "Found $search_string more than once per interval, exiting.\n";
                exit;
            }
        }
    }
    print "$interval $value\n";
    
    close inFILE;
}


my $num_args = $#ARGV + 1;
if ($num_args != 2) {
    print "usage: parse_tokustat.pl <input-file> <search-string>\n";
    exit;
}

my $parm_input_file = $ARGV[0];
my $parm_search_string = $ARGV[1];

parse_file($parm_input_file,$parm_search_string);
