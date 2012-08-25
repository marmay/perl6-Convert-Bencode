module Convert::Bencode;

use Convert::Bencode::X::NoConversionAvailable;
use Convert::Bencode::X::InvalidBlock;

=begin pod

=head1 NAME

Convert::Bencode -- Encodes and decodes Bencode

=head1 SYNOPSIS

  use Convert::Bencode;

  bencode("Hello"); # Returns "5:Hello"
  bencode(314);     # Returns "i314e"
  bencode({ foo => { bar => [1, 2, 3], abc => "3145" }, meh => "moooo" });
    # Returns d3:food3:barli1ei2ei3ee3:abc4:3145e3:meh5:mooooe

  bdecode("5:Hello"); # Returns "Hello"
  bdecode("i314e");   # Returns 314

=head1 DESCRIPTION

Bencode is a simple encoding that provides a bijective mapping between strings
and data structures consisting out of strings, integers, lists (i.e. arrays)
and dictionaries (i.e. hashes). It is used in the Bittorrent protocol. This
module provides two functions: C<bencode> for encoding and C<bdecode> for
decoding.

=head2 Encoding

Strings are encoded in a similar way to the netstrings encoding, but without
a trailing comma character. They contain the byte length of the string, i.e.
what Perl6's .bytes method returns, followed by a colon and finally followed by
the string data. For example, the string "Hello", becomes "5:Hello" in Bencode.

Integers in Bencode begin with an "i" followed by the number and an "e"
character. For example, 314 becomes "i314e".

Lists in Bencode begin with an "l" followed by all list elements and an "e".
For example, [314, "Hello"] becomes "li314e5:Helloe".

Dictionaries begin with a "d" followed by all pairs and an "e". For example,
{Hello => 314} becomes "d5:Helloi314ee". Keys have to be strings, but values
can be of abritary types.

=head2 Exceptions

C<Convert::Bencode> has two exception types:
C<Convert::Bencode::X::NoConversionAvailable> and
C<Convert::Bencode::X::InvalidBlock>.
The first one is thrown if a certain data type can't be encoded by bencode.
For example C<bencode(3.14)> will throw this exception, because there is no
conversion available for the type C<Num>. The other exception is thrown by
C<bdecode> if it can't parse some part of the string.

=head2 Subroutines

This module provides two subroutines: C<bencode> and C<bdecode>.

=head3 bencode

C<bencode> is a multi sub that takes either a C<Str>, C<Int>, arrays or
hashes. Arrays and hashes must contain only C<Str>, C<Int> or other arrays
or hashes, which themselves consist only out of C<Str>, C<Int>, arrays
or hashes, .... In addition, keys of hashes must be C<Str>s. If this is not
true, C<bencode> throws an exception of type
C<Convert::Bencode::X::NoConversionAvailable>. Otherwise, it returns a string
that contains the encoded data structure.

=end pod

multi sub bencode(Str $string) is export {
  "{$string.bytes}:$string"
}
multi sub bencode(Int $integer) is export {
  "i{$integer}e"
}
multi sub bencode(@data) is export {
  "l" ~ @data.map({ bencode($_) }).join('') ~ 'e'
}
multi sub bencode(%data) is export {
  for %data.keys -> $k {
    die Convert::Bencode::X::NoConversionAvailable.new(
          :type($k.WHAT.perl),
          :value($k),
          :context('dict'),
        ) unless $k.WHAT ~~ Str;
  }
  'd' ~ %data.kv.map({ bencode($_) }).join('') ~ 'e'
}
multi sub bencode($no-conversion) is export {
  die Convert::Bencode::X::NoConversionAvailable.new(
        :type($no-conversion.WHAT),
        :value($no-conversion));
}

=begin pod

=head3 bdecode

C<bdecode> takes a C<Str> that contains a Bencode encoded data structure. In
case that the string is not well-formed, this subroutine throws an exception
of type C<Convert::Bencode::X::InvalidBlock>. Otherwise, it returns the
corresponding data structure.

=end pod

sub bdecode(Str $str, :$encoding = 'utf-8') is export {
  my $to;
  my $bytes = $str.encode($encoding);
  my $decoded = bdecode-buf($bytes, 0, $to, $encoding);
  die Convert::Bencode::X::InvalidBlock.new(
          :byte-string($bytes), :from($to+1), :to($bytes.elems),
          :block-type('unknown'), :encoding($encoding),
          :reason('Invalid straw characters.'))
    unless $to == $bytes.elems-1;
  return $decoded;
}

sub bdecode-buf(Buf $bytes, $from, $to is rw, $encoding) {
  my $size = $bytes.elems;
  my $char = $bytes.[$from];
  given ($char.chr)
  {
    when 'd' { # Dictionary
      my @all;
      $to = $from + 1;
      until $to == $size-1 or $bytes.[$to].chr ~~ 'e' {
        my $next-to;
        @all.push: bdecode-buf($bytes, $to, $next-to, $encoding);
        $to = $next-to + 1;
      }

      die Convert::Bencode::X::InvalidBlock.new(
            :byte-string($bytes), :from($from), :to($to),
            :block-type('dict'), :encoding($encoding),
            :reason('dict does not end.'))
        unless $bytes.[$to].chr ~~ 'e';

      die Convert::Bencode::X::InvalidBlock.new(
            :byte-string($bytes), :from($from), :to($to),
            :block-type('dict'), :encoding($encoding),
            :reason('dict has an odd number of elements.'))
        unless @all.elems % 2 == 0;

      my %hash;
      for @all -> $k, $v {
        %hash{$k} = $v;
      }
      return %hash.item;
    }
    when 'l' { # List
      my @all;
      $to = $from + 1;
      until $bytes.[$to].chr ~~ 'e' {
        my $next-to;
        @all.push: bdecode-buf($bytes, $to, $next-to, $encoding);
        $to = $next-to + 1;
      }

      return @all.item;
    }
    when 'i' { # Integer
      $to = $from + 1;
      until $to == $size-1 or $bytes.[$to].chr ~~ 'e' {
        $to += 1;
      }

      die Convert::Bencode::X::InvalidBlock.new(
            :byte-string($bytes), :from($from), :to($to),
            :block-type('integer'), :encoding($encoding),
            :reason('Integer block does not end.'))
        unless $bytes.[$to].chr ~~ 'e';

      return $bytes[$from+1..$to-1]».chr.join('').Int;
    }
    when /<[0..9]>/ { # String
      $to = $from + 1;
      until $to == $size-1 or $bytes.[$to].chr ~~ ':' {
        die Convert::Bencode::X::InvalidBlock.new(
              :byte-string($bytes), :from($to), :to($to),
              :block-type('string'), :encoding($encoding),
              :reason('Length description of string contains ' ~
                      'a non-decimal character.'))
          unless $bytes.[$to].chr ~~ /<[0..9]>/;

        $to += 1;
      }

      die Convert::Bencode::X::InvalidBlock.new(
            :byte-string($bytes), :from($from), :to($to),
            :block-type('string'), :encoding($encoding),
            :reason('String does not contain a colon.'))
        unless $bytes.[$to].chr ~~ ':';

      my $number-chars = $bytes[$from..$to-1]».chr.join('').Int;

      die Convert::Bencode::X::InvalidBlock.new(
            :byte-string($bytes), :from($from), :to($to-1),
            :block-type('string'), :encoding($encoding),
            :reason('Length description of string exceeds length of ' ~
                    'byte stream.'))
        unless $to + $number-chars < $size;

      my $string-begin = $to + 1;
      my $string-end   = $to + $number-chars;
      $to = $string-end;

      return $bytes[$string-begin..$string-end]».chr.join('');
    }
    when * {
      die Convert::Bencode::X::InvalidBlock.new(
            :byte-string($bytes), :from($from), :to($from),
            :block-type('unknown'), :encoding($encoding),
            :reason('Invalid straw character.'));
    }
  }
}

=begin pod

=head1 KNOWN LIMITATIONS AND BUGS

C<Convert::Bencode::X::InvalidBlock> produces invalid output for strings
containing multi-byte characters.

=head1 AUTHORS

Markus Mayr, L<maxl.mayr@aon.at>

=head1 SEE ALSO

=begin item
  The BitTorrent protocol specification at
  L<http://www.bittorrent.org/beps/bep_0003.html>
=end item

=end pod

