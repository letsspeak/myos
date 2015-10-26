// kmath.c

int kmath_pow(int x, int n)
{
  int result = 1;
  while (n-- != 0) result = result * x;
  return result;
}

int kmath_sqrt(int x, int of)
{
  int result = 0;
  while ((x = x / of) != 0)
    result++;
  return result;
}

