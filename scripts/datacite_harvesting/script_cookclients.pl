#!/usr/bin/perl

while (<>)
{
    chop;
    ($alias, $set) = split;

    open IN, "template_client.json";

    open OUT, ">clients/" . $alias . ".json";

    while ($in=<IN>)
    {
	$in =~s/%ALIAS%/$alias/;
	$in =~s/%SET%/$set/;
	print OUT $in;
    }

    close OUT;
    close IN;

    print STDERR "created client for $alias\n";
}
