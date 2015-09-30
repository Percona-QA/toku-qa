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
    my $output_file = $input_file . ".parsed";
    
    my $line = "";
    my $good_lines = 0;
    my $bad_lines = 0;
    
    my @history_cpu;
    my @history_rss;
    my @history_vm;

    # create the output file
    open (outFILE, ">$output_file") || die "cannot open file for writing $!";
    
    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ m/mysqld/) {
            $good_lines++;
            # good line found
            # 20121101161805  2069  tcallagh  18   0 11.3g 8.8g 7772 S 103.9  12.4  49:50.24 mysqld                                                                                                                                    
            # [timestamp]     [pid] [user]           [vm]  [rss]       [%cpu] [%mem]
            
            #500      13163  0.0  0.0 731524 36500 pts/1    Sl   22:27   0:00 /data/tcallaghan/dbtest/bin/mysqld --defaults-file=my.cnf --basedir=/data/tcallaghan/dbtest --datadir=/data/tcallaghan/dbtest/data --core-file --log-error=/data/tcallaghan/dbtest/data/mindy.tokutek.com.err --pid-file=/data/tcallaghan/dbtest/data/mindy.tokutek.com.pid --port=3306
            #                [CPU]    [VM]   [RSS]
            my @line_values = split(' ', $line);

            my $this_cpu = $line_values[9];
            my $this_vm_gb = $line_values[5];
            my $this_rss_gb = $line_values[6];
            my $this_pct_ram = $line_values[10];
            my $this_timestamp = $line_values[0];

            push(@history_cpu, $this_cpu);
            push(@history_rss, $this_rss_gb);
            push(@history_vm, $this_vm_gb);

            print outFILE $this_timestamp . "\t" . $this_vm_gb . "\t" . $this_rss_gb . "\t" . $this_cpu . "\t" . $this_pct_ram . "\n";
        } else {
            $bad_lines++;
            # bad line, output info
            #print "BAD LINE FOUND: $line\n";
        }
    }
    
    # my $avg_cpu = average(\@history_cpu);
    # my $avg_rss = average(\@history_rss);
    # my $avg_vm = average(\@history_vm);
    
    print "found $good_lines good line(s) and $bad_lines bad line(s) in $input_file\n";
    print "created $output_file\n";
    # print "avg cpu = $avg_cpu, avg rss = $avg_rss, avg vm = $avg_vm\n";
    
    close inFILE;
    
    close outFILE;
}


my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "usage: parse-sysinfo.pl <input-file-directory>\n";
    exit;
}

my $parm_input_file_directory = $ARGV[0];

@files = <$parm_input_file_directory/*.sysinfo>;
foreach my $file (@files) {
    parse_file($file);
}

