#!/usr/bin/perl -w

sub trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub parse_file {
    my $input_file = shift;
    
    my $line = "";
    
    my $good_lines = 0;
    my $bad_lines = 0;
    my @output_file_lines;
    
    # open a file for reading
    open (inFILE, "$input_file") || die "cannot open file for reading $!";

    while (<inFILE>) {
        chomp;
        $line = $_;
        
        if ($line =~ /\[ pass \]/) {
            # good line
            $good_lines++;
            my @line_values = split(/\[ pass \]/, $line);
            #my $millis = sprintf("%10s",trim($line_values[1]));
            my $millis = sprintf("%010d",trim($line_values[1]));
            push(@output_file_lines, $millis . ' : ' . $line_values[0]);
        } else {
            $bad_lines++;
        }
    }

    $output_file = $input_file . ".out";
    open (outFILE, ">$output_file") || die "cannot open file for writing $!";
    
    for my $output_line (@output_file_lines) {
        print outFILE $output_line . "\n";
    }
    print "found $good_lines good line(s) and $bad_lines bad line(s) in $input_file\n";
    
    close inFILE;
}


if (@ARGV == 0) {
    print "usage: parse_mysql-test.pl <input file directory>\n";
    exit;
}

my $parm_input_file_spec = $ARGV[0];

@files = <$parm_input_file_spec/mysql-test*>;
foreach my $file (@files) {
    parse_file($file);
}
