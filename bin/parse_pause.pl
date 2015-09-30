#!/usr/bin/perl -w

if (@ARGV == 0) {
    print "usage: parse_pause.pl <input-file-directory>\n";
    exit;
}

my $parm_input_file_directory = $ARGV[0];

@files = <$parm_input_file_directory/*.txt>;
foreach my $iofile (@files) {
    my $iofile = $iofile . ".iostat";
    my $ioinfo = "arps 0 awps 0";
    if (-e $iofile) {
        $ioinfo = `parse_iostat.pl $iofile`;
    }
    my @io_details = split(' ', $ioinfo);
    my $arps = $io_details[1];
    my $awps = $io_details[3];
    
    printf("rps = %.2f : wps = %.2f\n", $arps, $awps);
}