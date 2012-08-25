class Convert::Bencode::X::InvalidBlock
  is Exception
{
  has $.byte-string is readonly;
  has $.from is readonly;
  has $.to is readonly;
  has $.block-type is readonly;
  has $.encoding is readonly;
  has $.reason is readonly;

  method message
  {
    my $error = "InvalidBlock of type $.block-type in byte stream of length " ~
                "{$.byte-string.elems} encoded with\n$.encoding at " ~
                "positions $.from to $.to:\n  $.reason\n";
    my $string = $.byte-string.decode($.encoding);

    my $rows = ($string.chars / 80).Int;
    loop (my $i = 0; $i < $rows+1; $i += 1)
    {
      my $line-from = $i * 80;
      my $line-to   = ($i+1) * 80 - 1;
      $error ~= $string.substr($line-from, $line-to) ~ "\n";
      unless ($.from < $line-from and $.to < $line-from) or
             ($.from > $line-to   and $.to > $line-to)
      {
        my $mark-from = max($.from - $line-from, 0);
        my $mark-to   = min($.to   - $line-from, 80);

        "Marking from $mark-from to $mark-to.".say;

        $error ~= (' ' x $mark-from) ~ ('^' x ($mark-to-$mark-from));
      }
    }

    return $error;
  }
}

