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
    my $parse_type = shift;
    
    my $file_state = "not-started";
    my $line = "";
    my $total_rows = 0;
    my $last_rows = 0;
    my $avg_qps = 0;
    my $total_seconds = 0;
    my $good_lines = 0;
    my $bad_lines = 0;
    my $avg_thruput_from_log = 0;
    
    my @recent_thruput;
    my @benchmark_detail_inserts;
    my @recent_thruput2;
    
    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ "#rows") {
            $file_state = "started";
        } elsif ($line =~ /Done/) {
            $file_state = "finished";
        } elsif ($file_state eq "started") {
            if ($line ne "") {
                #rows #seconds #total_seconds cum_ips table_size last_ips #queries cum_qps last_qps
                my @line_values = split(' ', $line);
                
                if ($line_values[0]) {
                    if ($line_values[0] eq "") {
                        $bad_lines++;
                        # bad line, output info
                        if ($parse_type eq "sql") {
                            print "BAD LINE FOUND: $line\n";
                        }
                    } else {
                        $good_lines++;
                        
                        my $this_rows = $line_values[0] - $last_rows;
                        my $this_seconds = $line_values[1];
                        #my $current_thruput = 0;
                        #if ($this_seconds > 0) {
                        #    $current_thruput = $this_rows / $this_seconds;
                        #}
                        my $current_thruput = $line_values[5];

                        my $this_qps = $line_values[8];

                        $last_rows = $line_values[0];
                        $avg_thruput_from_log = $line_values[3];
                        
                        $total_seconds += $this_seconds;
                        $total_rows += $this_rows;
                        $avg_qps = $line_values[7];
                       
                        if ($this_seconds > 0) { 
                            # keep last 60 results for exit thruput calculation
                            my $num_recent_thruput = @recent_thruput;
                            if ($num_recent_thruput > 60) {
                                shift(@recent_thruput);
                            }
                            push(@recent_thruput, $current_thruput);

                            # keep last 60 results for exit thruput2 calculation
                            my $num_recent_thruput2 = @recent_thruput2;
                            if ($num_recent_thruput2 > 60) {
                                shift(@recent_thruput2);
                            }
                            push(@recent_thruput2, $this_qps);
                        }

                        push(@benchmark_detail_inserts, "insert into benchmark_detail (benchmark_hdr_pk, duration, thruput, latency, thruput2) values ($hdr_pk, $total_rows, $current_thruput, -1, $this_qps);");
                    }
                } else {
                    $bad_lines++;
                    # bad line, output info
                    #print "BAD LINE FOUND: $line\n";
                }
            }
        }
    }
    
    #my $avg_thruput = $total_rows / $total_seconds;
    my $avg_thruput = $avg_thruput_from_log;
    my $exit_thruput = average(\@recent_thruput);
    my $exit_thruput2 = average(\@recent_thruput2);
    
    if ($parse_type eq "sql") {
        print outFILE "insert into benchmark_header (benchmark_hdr_pk, server_name, benchmark_name, benchmark_date, param01, param02, avg_thruput, avg_thruput2, exit_thruput, exit_thruput2, duration, engine_name, engine_version, database_name, database_version, commit_sync, extra_info) ";
        print outFILE "values ($hdr_pk, '$server_name', '$benchmark_name', '$benchmark_date', NULL, NULL, $avg_thruput, $avg_qps, $exit_thruput, $exit_thruput2, $total_seconds, '$engine_name', '$engine_version', '$database_name', '$database_version', '$commit_sync', '$extra_info');\n";
        print outFILE "\n";
        
        for my $dtl_insert (@benchmark_detail_inserts) {
            print outFILE $dtl_insert . "\n";
        }
        
        print outFILE "\n\n\n";
        print "found $good_lines good line(s) and $bad_lines bad line(s) in $input_file\n";
    } elsif (($parse_type eq "tps") || ($parse_type eq "summary")) {
        printf("avg-ips/exit-ips/exit-qps : %.1f / %.1f / %.1f\n", $avg_thruput, $exit_thruput, $exit_thruput2);
    } elsif ($parse_type eq "summary2") {
        my $iofile = $input_file . ".iostat";
        my $ioinfo = "arps 0 awps 0";
        if (-e $iofile) {
            $ioinfo = `parse_iostat.pl $iofile`;
        }
        my @io_details = split(' ', $ioinfo);
        my $arps = $io_details[1];
        my $awps = $io_details[3];
        my $opsPerRead = 0;
        my $opsPerWrite = 0;

        if ($benchmark_name =~ "IIBENCH.QUERY.ONLY") {
            # queries
            if ($exit_thruput2 > 0) {
                $opsPerRead = $arps / $exit_thruput2;
                $opsPerWrite = $awps / $exit_thruput2;
            }
            printf("exit-qps = %.2f : raf = %.2f : rps = %.2f : waf = %.2f : wps = %.2f\n", $exit_thruput2, $opsPerRead, $arps, $opsPerWrite, $awps);
        } else {
            # replace-intos
            if ($exit_thruput2 > 0) {
                $opsPerRead = $arps / $exit_thruput;
                $opsPerWrite = $awps / $exit_thruput;
            }
            printf("exit-ips = %.2f : raf = %.2f : rps = %.2f : waf = %.2f : wps = %.2f\n", $exit_thruput, $opsPerRead, $arps, $opsPerWrite, $awps);
        }
    }
    
    close inFILE;
}


if (@ARGV == 0) {
    print "usage: parse_iibench.pl <sql/tps/summary/summary2> <benchmark date in yyyy-mm-dd> <starting pk> <output file name> <input file spec>\n";
    exit;
}

my $parse_type = $ARGV[0];
my $num_args = $#ARGV + 1;
if (($parse_type eq "sql") && ($num_args != 5)) {
    print "usage: parse_iibench.pl sql <benchmark date in yyyy-mm-dd> <starting pk> <output file name> <input file dir>\n";
    exit;
} elsif (($parse_type eq "tps") && ($num_args != 2)) {
    print "usage: parse_iibench.pl tps <input file dir>\n";
    exit;
} elsif (($parse_type eq "summary") && ($num_args != 2)) {
    print "usage: parse_iibench.pl summary <input file dir>\n";
    exit;
} elsif (($parse_type eq "summary2") && ($num_args != 2)) {
    print "usage: parse_iibench.pl summary2 <input file dir>\n";
    exit;
} elsif (($parse_type ne "sql") && ($parse_type ne "tps") && ($parse_type ne "summary") && ($parse_type ne "summary2")) {
    print "usage: parse_iibench.pl sql/tps/summary/summary2\n";
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
}

@files = <$parm_input_file_directory/*.txt>;
foreach my $file (@files) {
    # get information out of the filename
    
    my $filename_without_path_or_extension = $file;
    $filename_without_path_or_extension =~ s/\.[^.]+$//;  # removes extension
    $filename_without_path_or_extension =~ s{.*/}{};      # removes path  
    
    my ($parm_server_name,$parm_database_name,$parm_database_version,$parm_engine_name,$parm_engine_version,$parm_benchmark_name,$parm_commit_sync,$parm_extra_info) = split("-",$filename_without_path_or_extension);
    
    if (!$parm_extra_info) {
        $parm_extra_info = "";
    }

    parse_file($file,$parm_server_name,$parm_benchmark_name,$parm_benchmark_date,$parm_engine_name,$parm_engine_version,$parm_database_name,$parm_database_version,$parm_commit_sync,$parm_starting_pk,$parm_extra_info,$parse_type);

    $parm_starting_pk++;
}

if ($parse_type eq "sql") {
    print outFILE "commit;\n\n\n";
    close outFILE;
}
