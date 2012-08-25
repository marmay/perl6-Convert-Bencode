class Convert::Bencode::X::NoConversionAvailable
  is Exception
{
  has $.type;
  has $.value;
  has $.context = 'generic';

  method message {
    "No conversion available in $.context context, because there is " ~
    "no conversion available for \"$.value\" of type " ~
    "{$.type || '"Unknown"'}.";
  }
}

