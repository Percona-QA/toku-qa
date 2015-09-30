#!/usr/bin/perl -w

sub trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

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
    my $server_name = shift;
    my $benchmark_name = shift;
    my $benchmark_date = shift;
    my $engine_name = shift;
    my $engine_version = shift;
    my $database_name = shift;
    my $database_version = shift;
    my $commit_sync = shift;
    my $hdr_pk = shift;
    my $extra_info = shift;
    my $loaded_rowcount = shift;
    my $threads = shift;
    my $parse_type = shift;
    
    my $file_state = "not-started";
    my $line = "";
    my $total_rows = 0;
    my $total_tps = 0;
    my $good_lines = 0;
    my $bad_lines = 0;
    my $last_seconds = 0;
    
    my @recent_thruput;
    my @benchmark_detail_inserts;
    
    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ "Threads started!") {
            $file_state = "started";
        } elsif ($line =~ "OLTP test statistics:") {
            $file_state = "finished";
        } elsif ($file_state eq "started") {
            if ($line ne "") {
                #[  10s] threads: 1, tps: 2.60, reads/s: 37.80, writes/s: 10.50 response time: 451.55ms (99%)
                #[  10s] threads: 1, tps: 0.00, reads: 16244.41, writes: 0.00, response time: 0.12ms (99%), errors: 0.00, reconnects:  0.00
                #  [0]                     [1]             [2]              [3]                   [4]
                #my @line_values = $line =~ /\[\s*(\d*).*: ([^,]*).*: ([^,]*).*: ([^ ]*).*: ([^m]*)/;
                my @line_values = $line =~ /\[\s*(\d*).*tps:\s(\d+\.?\d*).*reads:\s(\d+\.?\d*).*writes:\s(\d+\.?\d*).*response\stime:\s(\d+\.?\d*)/;

                if ($line_values[0]) {
                    if ($line_values[0] eq "") {
                        $bad_lines++;
                        # bad line, output info
                        if ($parse_type eq "sql") {
                            print "BAD LINE FOUND: $line\n";
                        }
                    } else {
                        $good_lines++;

                        my $this_seconds = $line_values[0];
                        my $this_thruput = $line_values[2];
                        my $this_latency = $line_values[4];

                        $total_rows++;
                        $total_tps += $this_thruput;
                        $last_seconds = $this_seconds;
                        
                        # keep last 90 results for exit thruput calculation
                        my $num_recent_thruput = @recent_thruput;
                        if ($num_recent_thruput > 90) {
                            shift(@recent_thruput);
                        }
                        push(@recent_thruput, $this_thruput);
                        push(@benchmark_detail_inserts, "insert into benchmark_detail (benchmark_hdr_pk, duration, thruput, latency) values ($hdr_pk, $this_seconds, $this_thruput, $this_latency);");
                    }
                } else {
                    $bad_lines++;
                    # bad line, output info
                    if ($parse_type eq "sql") {
                        print "BAD LINE FOUND: $line\n";
                    }
                }
            }
        }
    }
    
    my $avg_thruput = $total_tps / $total_rows;
    my $exit_thruput = average(\@recent_thruput);
    
    if ($parse_type eq "sql") {
        print outFILE "insert into benchmark_header (benchmark_hdr_pk, server_name, benchmark_name, benchmark_date, param01, param02, avg_thruput, exit_thruput, duration, engine_name, engine_version, database_name, database_version, commit_sync, extra_info) ";
        print outFILE "values ($hdr_pk, '$server_name', '$benchmark_name', '$benchmark_date', '$loaded_rowcount', '$threads', $avg_thruput, $exit_thruput, $last_seconds, '$engine_name', '$engine_version', '$database_name', '$database_version', '$commit_sync', '$extra_info');\n";
        print outFILE "\n";
    
        for my $dtl_insert (@benchmark_detail_inserts) {
            print outFILE $dtl_insert . "\n";
        }
    
        print outFILE "\n\n\n";
        print "found $good_lines good line(s) and $bad_lines bad line(s) in $input_file\n";
    } elsif (($parse_type eq "tps") || ($parse_type eq "summary")) {
        printf("threads/avg/exit : %d / %.1f / %.1f\n", $threads, $avg_thruput, $exit_thruput);
    }
        
    
    close inFILE;
}


if (@ARGV == 0) {
    print "usage: parse_fbpileup.pl <sql/tps/summary> <benchmark date in yyyy-mm-dd> <starting pk> <output file name> <input file spec>\n";
    exit;
}

my $parse_type = $ARGV[0];
my $num_args = $#ARGV + 1;
if (($parse_type eq "sql") && ($num_args != 5)) {
    print "usage: parse_fbpileup.pl sql <benchmark date in yyyy-mm-dd> <starting pk> <output file name> <input file dir>\n";
    exit;
} elsif (($parse_type eq "tps") && ($num_args != 2)) {
    print "usage: parse_fbpileup.pl tps <input file dir>\n";
    exit;
} elsif (($parse_type eq "summary") && ($num_args != 2)) {
    print "usage: parse_fbpileup.pl summary <input file dir>\n";
    exit;
} elsif (($parse_type ne "sql") && ($parse_type ne "tps") && ($parse_type ne "summary")) {
    print "usage: parse_fbpileup.pl sql/tps/summary\n";
    exit;
}    

my $parm_benchmark_date = "1999-12-31";
my $parm_starting_pk = "1";
my $parm_output_file = "dummy.file.txt";
my $parm_input_file_directory = ".";
if ($parse_type eq "sql") {
    $parm_benchmark_date = $ARGV[1];
    $parm_starting_pk = $ARGV[2];
    $parm_output_file = $ARGV[3];
    $parm_input_file_directory = $ARGV[4];
} else {
    $parm_input_file_directory = $ARGV[1];
}

if ($parse_type eq "sql") {
    open (outFILE, ">$parm_output_file") || die "cannot open file for writing $!";
    print outFILE "set autocommit = off;\n\n\n";

    @files = <$parm_input_file_directory/*.txt>;
    foreach my $file (@files) {
        # get information out of the filename
        my $filename_without_path_or_extension = $file;
        $filename_without_path_or_extension =~ s/\.[^.]+$//;  # removes extension
        $filename_without_path_or_extension =~ s{.*/}{};      # removes path  

        
        my ($parm_server_name,$parm_database_name,$parm_database_version,$parm_engine_name,$parm_engine_version,$parm_benchmark_name,$parm_rowcount,$parm_threads,$parm_commit_sync,$parm_extra_info) = split("-",$filename_without_path_or_extension);
        
        if (!$parm_extra_info) {
            $parm_extra_info = "";
        }
    
        parse_file($file,$parm_server_name,$parm_benchmark_name,$parm_benchmark_date,$parm_engine_name,$parm_engine_version,$parm_database_name,$parm_database_version,$parm_commit_sync,$parm_starting_pk,$parm_extra_info,$parm_rowcount,$parm_threads,$parse_type);
    
        $parm_starting_pk++;
    }

    print outFILE "commit;\n\n\n";
    close outFILE;
} else {
    my @bench_type = ('POINT.PRIMARY','POINT.SECONDARY','RANGE.PRIMARY','RANGE.SECONDARY');
    
    for my $this_bench (@bench_type) {
        print "$this_bench\n";
        @files = <$parm_input_file_directory/*.$this_bench.txt>;
        foreach my $file (@files) {
            # get information out of the filename
            my $filename_without_path_or_extension = $file;
            $filename_without_path_or_extension =~ s/\.[^.]+$//;  # removes extension
            $filename_without_path_or_extension =~ s{.*/}{};      # removes path  

            
            my ($parm_server_name,$parm_database_name,$parm_database_version,$parm_engine_name,$parm_engine_version,$parm_benchmark_name,$parm_rowcount,$parm_threads,$parm_commit_sync,$parm_extra_info) = split("-",$filename_without_path_or_extension);
            
            if (!$parm_extra_info) {
                $parm_extra_info = "";
            }
        
            parse_file($file,$parm_server_name,$parm_benchmark_name,$parm_benchmark_date,$parm_engine_name,$parm_engine_version,$parm_database_name,$parm_database_version,$parm_commit_sync,$parm_starting_pk,$parm_extra_info,$parm_rowcount,$parm_threads,$parse_type);
        
            $parm_starting_pk++;
        }
    }
}
