use v6;
use Test;
use Convert::Bencode;

plan 7;

is bencode("Test"), "4:Test",
  "can encode short strings";
is bencode("Hello, World"), "12:Hello, World",
  "can encode long strings";
is bencode(152), "i152e",
  "can encode integers";
is bencode(Array.new("Test", 152, "Hallo", "Welt", 143, 4, 150000)),
  "l4:Testi152e5:Hallo4:Welti143ei4ei150000ee",
  "can encode arrays";
my @a = "Test", 152, "Hallo", "Welt", 143, 4, 150000;
is bencode(@a),
  "l4:Testi152e5:Hallo4:Welti143ei4ei150000ee",
  "can encode arrays";
my %h = "Test" => 5, "XY" => 17;
is bencode(%h), "d4:Testi5e2:XYi17ee",
  "can encode simple arrays";
dies_ok { bencode(3.14) }, "dies ok for Rat";

