[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Content Module]](https://pdf-raku.github.io/PDF-Content-raku)
 / [PDF::Content](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content)
 :: Text
 :: [Style](https://pdf-raku.github.io/PDF-Content-raku/PDF/Content/Text/Style)

class PDF::Content::Text::Style
-------------------------------

style setting for a text box

Methods
-------

### multi method baseline-shift

```raku
multi method baseline-shift(
    Str $_ where { ... }
) returns Numeric
```

compute a vertical offset for a named font alignment mode

This returns a positive or negative y-offset in units of points. The default is `alphabetic`, which is a zero offset. 

### multi method baseline-shift

```raku
multi method baseline-shift() returns Mu
```

get/set a numeric font vertical alignment offset

### method space-width

```raku
method space-width() returns Mu
```

return the scaled width of spaces

### method underline-position

```raku
method underline-position() returns Mu
```

return the scaled underline position

### method underline-thickness

```raku
method underline-thickness() returns Mu
```

return the scaled underline thickness

### method font-height

```raku
method font-height(
    |c
) returns Mu
```

return the scaled font height

