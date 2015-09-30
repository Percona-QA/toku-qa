#!/usr/bin/perl -w

sub trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

my $commandLineArgs = $#ARGV + 1;

if ($commandLineArgs == 0) {
    print "usage: benchmark-summary.pl <output-file> <optional-comparison-file> [-k]\n";
    exit;
}

my $parm_output_file = $ARGV[0];
open (outFILE, ">$parm_output_file") || die "cannot open file for writing $!";

my $keep_directories = 0;
if (/-k/ ~~ @ARGV) {
    # keep the directories created by the tarballs
    $keep_directories = 1;
    $commandLineArgs--;
}

my $do_compare = 0;
if ($commandLineArgs == 2) {
    $do_compare = 1;
    $parm_input_file = $ARGV[1];
}

my @dirs = grep { -d } glob './*';

foreach my $dir (@dirs) {
    if ($dir =~ ".SKIP") {
        # skip over this directory
        next;
    }
    
    print outFILE "*******************************************************************************************************\n";
    print outFILE "directory : $dir\n";
    print outFILE "*******************************************************************************************************\n";
    
    @files = <$dir/*.tar.gz>;
    foreach my $file (@files) {
        #print "  file : $file\n";
        
        # get information out of the filename
        my $filename_without_path_or_extension = $file;
        $filename_without_path_or_extension =~ s/\.[^.]+$//;  # removes extension .gz
        $filename_without_path_or_extension =~ s/\.[^.]+$//;  # removes extension .tar
        $filename_without_path_or_extension =~ s{.*/}{};      # removes path  
        
        # create directory
        mkdir "$dir/$filename_without_path_or_extension";
        
        # untar files
        system("tar -C $dir/$filename_without_path_or_extension -xzf $file");
        
        my ($machine_name,$benchmark_number,$date_time,$benchmark_type,$everything_else) = split("-",$filename_without_path_or_extension);
        
        if (($benchmark_type eq "mongoiibench") || ($benchmark_type eq "mongoSysbench")) {
            print outFILE "$benchmark_type : ($filename_without_path_or_extension)\n";
        } else {
            print outFILE "$benchmark_type : $everything_else\n";
        }

#        print " *** $file\n";
        
        if ($benchmark_type eq "sysbench") {
            my $summary = `parse_sysbench.pl summary $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "tpcc") {
            my $summary = `parse_tpcc.pl summary $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "fbpileup") {
            my $summary = `parse_fbpileup.pl summary $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "iibench") {
            my $summary = `parse_iibench.pl summary $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "iibench.queries") {
            my $summary = `parse_iibench.pl summary $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type =~ "IIBENCH.QUERY.ONLY") {
            my $summary = `parse_iibench.pl summary2 $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type =~ "IIBENCH.REPLACE.INTO") {
            my $summary = `parse_iibench.pl summary2 $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type =~ "PAUSE") {
            my $summary = `parse_pause.pl $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "mongoSysbench") {
            my $summary = `parse_mongo_sysbench.bash $dir/$filename_without_path_or_extension $filename_without_path_or_extension mongoSysbenchExecute`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "mongoSysbenchPileup") {
            my $summary = `parse_mongo_sysbench_pileup.bash $dir/$filename_without_path_or_extension $filename_without_path_or_extension mongoSysbenchPileup`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "mongoiibench") {
            my $summary = `parse_mongo_iibench.pl summary $dir/$filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } elsif ($benchmark_type eq "mongoYcsbLoad") {
            my $summary = `parse_mongo_ycsb.bash $dir/$filename_without_path_or_extension $filename_without_path_or_extension`;
            print outFILE "$summary\n";
        } else {
            print outFILE "    UNKNOWN BENCHMARK TYPE!\n";
        }
    }
}

close outFILE;


# do the memory checks
my @rss_high_water_marks;
@files = <*/*/*.memory>;
foreach my $file (@files) {
    #print "  memory checking : $file\n";
    my $mem_used_kb = `cut -d " " -f 2 $file | sort -n | tail -n 1`;
    my $mem_used_gb = $mem_used_kb / 1024 / 1024;
    #print "$mem_used_gb GB\n";
    push(@rss_high_water_marks,$mem_used_gb);
}

# sort and print the high water marks
my @sorted_rss_high_water_marks = sort {$a <=> $b} @rss_high_water_marks; 
print "*** RSS HIGH WATER MARKS (in GB) ***\n";
for my $this_rss (@sorted_rss_high_water_marks) {
    print "  $this_rss\n";
}

# cleanup directories
if ($keep_directories == 0) {
    my @dirs2 = grep { -d } glob './*/*';
    foreach my $dir2 (@dirs2) {
        # remove directory
        system("rm -rf $dir2");
    }
}




if ($do_compare == 1) {
    open (inFILE1, "$parm_output_file") || die "cannot open file for reading $!";
    my @lines1 = <inFILE1>;
    close inFILE1;

    open (inFILE2, "$parm_input_file") || die "cannot open file for reading $!";
    my @lines2 = <inFILE2>;
    close inFILE2;

    open (outFILE, ">$parm_output_file.compare") || die "cannot open file for writing $!";
    
    print outFILE "*******************************************************************************************************\n";
    print outFILE "comparing $parm_output_file to $parm_input_file\n";
    print outFILE "*******************************************************************************************************\n\n\n";

    foreach my $l1 (@lines1) {
        chomp($l1);
        my $l2 = shift @lines2;
        chomp($l2);
        
        my $tps1 = 0;
        my $tps2 = 0;
        my $result_line = 0;
        
        # check that $l1 contains a benchmark result line
        if (($l1 =~ /avg-ips\/exit-ips\/exit-qps/) || ($l1 =~ /threads\/avg\/exit/)) {
            my @lv1 = split(':', $l1);
            my @lv2 = split('\/', $lv1[1]);
            $tps1 = trim($lv2[1]);
            $result_line = 1;
        }
            
        # check that $l2 contains a benchmark result line
        if (($l2 =~ /avg-ips\/exit-ips\/exit-qps/) || ($l2 =~ /threads\/avg\/exit/)) {
            my @lv1 = split(':', $l2);
            my @lv2 = split('\/', $lv1[1]);
            $tps2 = trim($lv2[1]);
        }
        
        my $string_pct_diff = "";
        
        if (($tps1 > 0) && ($tps2 > 0)) {
            my $value_pct_diff = (($tps1 - $tps2) / $tps2) * 100;
            my $tens_pct_diff = int(abs($value_pct_diff));
            $string_pct_diff = "   (was $tps2, " . sprintf("%.2f", $value_pct_diff) . "%)";
            if ($value_pct_diff < 0) {
                $string_pct_diff .= "  " . '-' x $tens_pct_diff;
            } else {
                $string_pct_diff .= "  " . '+' x $tens_pct_diff;
            }
        }
        
        print outFILE "$l1" . "$string_pct_diff" . "\n";
        # print outFILE "  ** $tps1 ** $tps2 **\n";
    }
        
    close outFILE;
}
