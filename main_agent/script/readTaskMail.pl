use LWP::Simple;
$tsm = @ARGV[0];
open(MC,"mailConfig.txt");
while (<MC>) {
    $line = $_;
    if ($line =~ /ip\s+(\S+)/) {
        $ip = $1;
    }
}
my $url = "$ip\/$tsm";
#print $url;
my $content = get($url);
open OUT, "> $tsm" or die "Error: Can't open $tsm for write\n" ;
if ($content) {
    print OUT $content;
} else {
    print "No content";
}
close OUT;
