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
    
    my $line = "";
    my $checkpoints_found=0;
    
    my @history_checkpoints;
    
    my $benchmark_begin_epoch=-1;
    my $last_begin_epoch=0;
    my $last_ended_epoch=0;

    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        #TokuDB	checkpoint: last complete checkpoint began 	Sun Jan 13 15:12:38 2013
        #TokuDB	checkpoint: last complete checkpoint ended	Sun Jan 13 15:12:38 2013

        if (($line =~ m/time now/) && ($benchmark_begin_epoch == -1)) {
            # get first instance of "time now" for benchmark begin epoch
            # time now | Sun Jan 27 09:14:23 2013 | Sun Jan 27 09:14:33 2013
            # starting time of the benchmark
            my @line_values = split(' \| ', $line);
            $benchmark_begin_epoch = str2time($line_values[2]);
        }

        if ($line =~ m/last complete checkpoint began/) {
            # found a new checkpoint began statement, save the epoch
            my @line_values = split(' \| ', $line);
            #$last_begin_epoch = `date -d "$line_values[2]" +%s`;
            $last_begin_epoch = str2time($line_values[2]);
        }

        if ($line =~ m/last complete checkpoint ended/) {
            # found a new checkpoint ended statement, save the epoch
            my @line_values = split(' \| ', $line);
            #$last_ended_epoch = `date -d "$line_values[2]" +%s`;
            $last_ended_epoch = str2time($line_values[2]);
            my $this_checkpoint_seconds = $last_ended_epoch - $last_begin_epoch;
            my $this_checkpoint_began = $last_begin_epoch - $benchmark_begin_epoch;
            $checkpoints_found++;
            push(@history_checkpoints,$this_checkpoint_seconds);
            #print "checkpoint " . $checkpoints_found . " started at " . $this_checkpoint_began . " and took " . $this_checkpoint_seconds . " second(s)\n";
            my $avg_cp = sprintf("%.1f", average(\@history_checkpoints));
            print "$checkpoints_found $this_checkpoint_began $this_checkpoint_seconds $avg_cp\n";
        }
    }
    
    #if ($checkpoints_found > 0) {
    #    my $avg_cp = average(\@history_checkpoints);
    #    print "average checkpoint was " . $avg_cp . " second(s)\n";
    #} else {
    #    print "no checkpoints found, no average to report\n";
    #}
    
    close inFILE;
}


my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "usage: parse_engine_checkpoints.pl <input-file>\n";
    exit;
}

my $parm_input_file = $ARGV[0];

parse_file($parm_input_file);
