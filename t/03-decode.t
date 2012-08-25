use v6;
use Test;
use Convert::Bencode;

plan 8;

is bdecode('i314e'), 314,
    'integer';
is bdecode('le'), [],
    'empty list';
is bdecode('llee'), [[]],
    'list containing empty list';
is bdecode('li314ei522ee'), [314, 522],
    'list of integers';
is bdecode('5:hello'), 'hello',
    'decode simple string';
is bdecode('l5:helloi314e5:worlde'), ['hello', 314, 'world'],
    'decode list of strings';
is bdecode('d5:hello5:worlde'),
    {hello => "world"},
    'decode dict';
is bdecode('d5:perl6d5:helloi314e5:worldi522ee5:perl5i17ee'),
    {perl6 => {hello => 314, world => 522}, perl5 => 17},
    'decode dict';

