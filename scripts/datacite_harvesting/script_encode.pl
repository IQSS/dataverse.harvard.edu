#!/usr/bin/perl

#echo "doi%3A(10.7910/DVN/TJCLKP%20OR%2010.7910/DVN/VL7QMO)"

print "doi%3A(";

while (<>)
{
    chop;
    ~tr/a-z/A-Z/;
    push(@DOIS, $_);
}

print join ("%20OR%20", @DOIS);

print ")\n";

