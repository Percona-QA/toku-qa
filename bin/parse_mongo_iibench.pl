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
    my $parse_type = shift;
    my $benchmark_name = shift;
    
    my $file_state = "not-started";
    my $line = "";
    my $total_rows = 0;
    my $last_rows = 0;
    my $avg_qps = 0;
    my $total_seconds = 0;
    my $good_lines = 0;
    my $bad_lines = 0;
    
    my @recent_ips;
    my @benchmark_detail_inserts;
    my @recent_qps;
    
    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ "tot_inserts") {
            $file_state = "started";
        #} elsif ($line =~ /Done/) {
        #    $file_state = "finished";
        } elsif ($file_state eq "started") {
            if ($line ne "") {
                #rows #seconds #total_seconds cum_ips table_size last_ips #queries cum_qps last_qps
                #tot_inserts	elap_secs	cum_ips	int_ips	cum_qry_avg	int_qry_avg
                my @line_values = split('\t', $line);
                
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
                        my $this_seconds = $line_values[1] - $total_seconds;
                        my $current_ips = 0;
                        if ($this_seconds > 0) {
                            $current_ips = $this_rows / $this_seconds;
                        }

                        my $this_qps = $line_values[5];

                        $last_rows = $line_values[0];
                        
                        $total_seconds += $this_seconds;
                        $total_rows += $this_rows;
                        $avg_qps = $line_values[4];
                       
                        if ($this_seconds > 0) { 
                            # keep last 60 results for exit ips calculation
                            my $num_recent_ips = @recent_ips;
                            if ($num_recent_ips > 60) {
                                shift(@recent_ips);
                            }
                            push(@recent_ips, $current_ips);

                            # keep last 60 results for exit qps calculation
                            my $num_recent_qps = @recent_qps;
                            if ($num_recent_qps > 60) {
                                shift(@recent_qps);
                            }
                            push(@recent_qps, $this_qps);
                        }

#                        push(@benchmark_detail_inserts, "insert into benchmark_detail (benchmark_hdr_pk, duration, thruput, latency, thruput2) values ($hdr_pk, $total_rows, $current_ips, -1, $this_qps);");
                    }
                } else {
                    $bad_lines++;
                    # bad line, output info
                    #print "BAD LINE FOUND: $line\n";
                }
            }
        }
    }
    
    my $avg_ips = $total_rows / $total_seconds;
    my $exit_ips = average(\@recent_ips);
    my $exit_qps = average(\@recent_qps);
    
    if ($parse_type eq "sql") {
#        print outFILE "insert into benchmark_header (benchmark_hdr_pk, server_name, benchmark_name, benchmark_date, param01, param02, avg_thruput, avg_thruput2, exit_thruput, exit_thruput2, duration, engine_name, engine_version, database_name, database_version, commit_sync, extra_info) ";
#        print outFILE "values ($hdr_pk, '$server_name', '$benchmark_name', '$benchmark_date', NULL, NULL, $avg_ips, $avg_qps, $exit_ips, $exit_qps, $total_seconds, '$engine_name', '$engine_version', '$database_name', '$database_version', '$commit_sync', '$extra_info');\n";
#        print outFILE "\n";
        
        for my $dtl_insert (@benchmark_detail_inserts) {
            print outFILE $dtl_insert . "\n";
        }
        
        print outFILE "\n\n\n";
        print "found $good_lines good line(s) and $bad_lines bad line(s) in $input_file\n";
    } elsif (($parse_type eq "tps") || ($parse_type eq "summary")) {
        printf("avg-ips/exit-ips/exit-qps : %d / %.1f / %.1f\n", $avg_ips, $exit_ips, $exit_qps);
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
            if ($exit_qps > 0) {
                $opsPerRead = $arps / $exit_qps;
                $opsPerWrite = $awps / $exit_qps;
            }
            printf("exit-qps = %.2f : raf = %.2f : rps = %.2f : waf = %.2f : wps = %.2f\n", $exit_qps, $opsPerRead, $arps, $opsPerWrite, $awps);
        } else {
            # replace-intos
            if ($exit_ips > 0) {
                $opsPerRead = $arps / $exit_ips;
                $opsPerWrite = $awps / $exit_ips;
            }
            printf("exit-ips = %.2f : raf = %.2f : rps = %.2f : waf = %.2f : wps = %.2f\n", $exit_ips, $opsPerRead, $arps, $opsPerWrite, $awps);
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

@files = <$parm_input_file_directory/*.tsv>;
foreach my $file (@files) {
    # get information out of the filename
    
    my $filename_without_path_or_extension = $file;
    $filename_without_path_or_extension =~ s/\.[^.]+$//;  # removes extension
    $filename_without_path_or_extension =~ s{.*/}{};      # removes path  
    
    my ($parm_server_name,$parm_benchmark_name,$parm_num_collections,$parm_max_rows,$parm_documents_per_insert,$parm_max_inserts_per_second,$parm_num_loader_threads,$parm_mongo_type) = split("-",$filename_without_path_or_extension);
    
    if (!$parm_extra_info) {
        $parm_extra_info = "";
    }

    parse_file($file,$parse_type,$parm_benchmark_name);

    $parm_starting_pk++;
}

if ($parse_type eq "sql") {
    print outFILE "commit;\n\n\n";
    close outFILE;
}
