#!/usr/bin/perl

print "doi%3A(";

while (<>)
{
    chop;
    ~tr/a-z/A-Z/;
    push(@DOIS, $_);
}

print join ("%20OR%20", @DOIS);

print ")\n";

