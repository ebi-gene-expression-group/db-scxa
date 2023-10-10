# Return the index of the first field that matches the given pattern, or 0 if it’s not found
{
  for (i = 1; i <= NF; ++i) {
    field = $i;
    if (field ~ pattern) {
      print i;
      exit;
    }
  }

  print 0;
  exit;
}
