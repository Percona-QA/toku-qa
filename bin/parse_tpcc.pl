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
    my $num_clients = shift;
    my $num_warehouses = shift;
    my $engine_name = shift;
    my $engine_version = shift;
    my $database_name = shift;
    my $database_version = shift;
    my $commit_sync = shift;
    my $hdr_pk = shift;
    my $extra_info = shift;
    my $raw_filename = shift;
    my $parse_type = shift;
    
    my $file_state = "not-started";
    my $line = "";
    my $total_thruput = 0;
    my $final_distance = 0;
    my $good_lines = 0;
    my $bad_lines = 0;
    
    my @recent_thruput;
    my @benchmark_detail_inserts;
    
    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    if ($parse_type eq "tps") {
        my $outfile_name = $raw_filename . ".tps";
        open (outFILE, ">$outfile_name") || die "cannot open file for writing $!";
    }

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line eq "MEASURING START.") {
            $file_state = "started";
        } elsif ($line =~ /STOPPING THREADS/) {
            $file_state = "finished";
        }
        
        if (($line ne "") && ($line ne "MEASURING START.") && ($file_state eq "started")) {
            # 10, 88(0):2.426|2.453, 89(0):0.452|0.587, 9(0):0.235|0.265, 9(0):2.834|2.849, 10(0):7.690|8.001
            my ($dist, $new_ord_details, $payment_details, $ord_stat_details, $delivery_details, $stock_level_details) = split(',', $line);

            if ($stock_level_details) {
                # 88(0):2.426|2.453
                my ($new_ord, $new_ord_late, $new_ord_lat_90, $new_ord_lat_int_max) = $new_ord_details =~ /\ (\d*)\((\d*)\):(\d*\.\d*)\|(\d*\.\d*)/;
                my ($payment, $payment_late, $payment_lat_90, $payment_lat_int_max) = $payment_details =~ /\ (\d*)\((\d*)\):(\d*\.\d*)\|(\d*\.\d*)/;
                my ($ord_stat, $ord_stat_late, $ord_stat_lat_90, $ord_stat_lat_int_max) = $ord_stat_details =~ /\ (\d*)\((\d*)\):(\d*\.\d*)\|(\d*\.\d*)/;
                my ($delivery, $delivery_late, $delivery_lat_90, $delivery_lat_int_max) = $delivery_details =~ /\ (\d*)\((\d*)\):(\d*\.\d*)\|(\d*\.\d*)/;
                my ($stock_level, $stock_level_late, $stock_level_lat_90, $stock_level_lat_int_max) = $stock_level_details =~ /\ (\d*)\((\d*)\):(\d*\.\d*)\|(\d*\.\d*)/;

                my $new_ord_lat = $new_ord_lat_int_max;
                my $payment_lat = $payment_lat_int_max;
                my $ord_stat_lat = $ord_stat_lat_int_max;
                my $delivery_lat = $delivery_lat_int_max;
                my $stock_level_lat = $stock_level_lat_int_max;
                
                $dist = trim($dist);
                $new_ord = trim($new_ord);
                $new_ord_late = trim($new_ord_late);
                $new_ord_lat = trim($new_ord_lat);
                $payment = trim($payment);
                $payment_late = trim($payment_late);
                $payment_lat = trim($payment_lat);
                $ord_stat = trim($ord_stat);
                $ord_stat_late = trim($ord_stat_late);
                $ord_stat_lat = trim($ord_stat_lat);
                $delivery = trim($delivery);
                $delivery_late = trim($delivery_late);
                $delivery_lat = trim($delivery_lat);
                $stock_level = trim($stock_level);
                $stock_level_late = trim($stock_level_late);
                $stock_level_lat = trim($stock_level_lat);
                
                if ($stock_level_lat eq "") {
                    $bad_lines++;
                    # bad line, output info
                    #print "BAD LINE FOUND: $line\n";
                } else {
                    $good_lines++;
                    $total_thruput += $new_ord;
                    $final_distance = $dist;
                    
                    # keep last 60 results for exit thruput calculation
                    my $num_recent_thruput = @recent_thruput;
                    if ($num_recent_thruput > 60) {
                        shift(@recent_thruput);
                    }
                    push(@recent_thruput, $new_ord);
                    push(@benchmark_detail_inserts, "insert into benchmark_detail (benchmark_hdr_pk, duration, thruput, latency) values ($hdr_pk, $dist, $new_ord, $new_ord_lat);");
                    
                    if ($parse_type eq "tps") {
                        print outFILE "$dist $new_ord\n";
                    }
                }
            } else {
                $bad_lines++;
                # bad line, output info
                #print "BAD LINE FOUND: $line\n";
            }
        }
    }
    
    my $avg_thruput = $total_thruput / $final_distance * 10;
    my $exit_thruput = average(\@recent_thruput);

    if ($parse_type eq "sql") {
        print outFILE "insert into benchmark_header (benchmark_hdr_pk, server_name, benchmark_name, benchmark_date, param01, param02, avg_thruput, exit_thruput, duration, engine_name, engine_version, database_name, database_version, commit_sync, extra_info) ";
        print outFILE "values ($hdr_pk, '$server_name', '$benchmark_name', '$benchmark_date', '$num_clients', '$num_warehouses', $avg_thruput, $exit_thruput, $final_distance, '$engine_name', '$engine_version', '$database_name', '$database_version', '$commit_sync', '$extra_info');\n";
        print outFILE "\n";
        
        for my $dtl_insert (@benchmark_detail_inserts) {
            print outFILE $dtl_insert . "\n";
        }
        
        print outFILE "\n\n\n";
        print "found $good_lines good line(s) and $bad_lines bad line(s) in $input_file\n";
    }

    if ($parse_type eq "summary") {
        printf("threads/avg/exit : %d / %.1f / %.1f\n", $num_clients, $avg_thruput, $exit_thruput);
    }

    close inFILE;
    
    if ($parse_type eq "tps") {
        close outFILE;
    }

}


if (@ARGV == 0) {
    print "usage: parse_tpcc.pl <sql/tps/summary> <benchmark date in yyyy-mm-dd> <starting pk> <output file name> <input file spec>\n";
    exit;
}

my $parse_type = $ARGV[0];
my $num_args = $#ARGV + 1;
if (($parse_type eq "sql") && ($num_args != 5)) {
    print "usage: parse_tpcc.pl sql <benchmark date in yyyy-mm-dd> <starting pk> <output file name> <input file dir>\n";
    exit;
} elsif (($parse_type eq "tps") && ($num_args != 2)) {
    print "usage: parse_tpcc.pl tps <input file dir>\n";
    exit;
} elsif (($parse_type eq "summary") && ($num_args != 2)) {
    print "usage: parse_tpcc.pl summary <input file dir>\n";
    exit;
} elsif (($parse_type ne "sql") && ($parse_type ne "tps") && ($parse_type ne "summary")) {
    print "usage: parse_tpcc.pl sql/tps/summary\n";
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
    
    my ($parm_server_name,$parm_database_name,$parm_database_version,$parm_engine_name,$parm_engine_version,$parm_benchmark_name,$parm_num_warehouses,$parm_num_clients,$parm_commit_sync,$parm_extra_info) = split("-",$filename_without_path_or_extension);
    
    if (!$parm_extra_info) {
        $parm_extra_info = "";
    }

    parse_file($file,$parm_server_name,$parm_benchmark_name,$parm_benchmark_date,$parm_num_clients,$parm_num_warehouses,$parm_engine_name,$parm_engine_version,$parm_database_name,$parm_database_version,$parm_commit_sync,$parm_starting_pk,$parm_extra_info,$filename_without_path_or_extension,$parse_type);

    $parm_starting_pk++;
}

if ($parse_type eq "sql") {
    print outFILE "commit;\n\n\n";
    close outFILE;
}