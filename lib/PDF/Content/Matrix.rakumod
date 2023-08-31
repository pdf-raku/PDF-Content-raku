#| PDF matrix utility functions
unit module PDF::Content::Matrix;

=begin pod
=head2 Description

Designed to work on PDF text and graphics transformation matrices of the form:

 [ a b 0 ]
 [ c d 0 ]
 [ e f 1 ]

where C<a b c d e f> are stored in a six digit array and the third column is implied.

=end pod

subset TransformMatrix is export(:TransformMatrix) of List where {.elems == 6}
my Int enum TransformMatrixElem « :a(0) :b(1) :c(2) :d(3) :e(4) :f(5) »;

our sub identity returns TransformMatrix is export(:identity) {
    [1, 0, 0, 1, 0, 0];
}

our sub translate(Numeric $x!, Numeric $y = $x --> TransformMatrix) is export(:translate) {
    [1, 0, 0, 1, $x, $y];
}

our sub reflect( Numeric \r --> TransformMatrix) is export(:reflect) {
    my Numeric \cos2r = cos(2 * r);
    my Numeric \sin2r = sin(2 * r);

    [cos2r, sin2r, sin2r, -cos2r, 0, 0];
}

our sub rotate( Numeric \r --> TransformMatrix) is export(:rotate) {
    my Numeric \cos-r = cos(r);
    my Numeric \sin-r = sin(r);

    [cos-r, sin-r, -sin-r, cos-r, 0, 0];
}

our sub scale(Numeric $x!, Numeric $y = $x --> TransformMatrix) is export(:scale)  {
    [$x, 0, 0, $y, 0, 0];
}

our sub skew(Numeric $x, Numeric $y = $x --> TransformMatrix) is export(:skew) {
    [1, tan($x), tan($y), 1, 0, 0];
}

#| multiply transform matrix x X y
our sub multiply(TransformMatrix \x, TransformMatrix \y --> TransformMatrix) is export(:multiply) {

    [ y[a] * x[a]  +  y[c] * x[b],
      y[b] * x[a]  +  y[d] * x[b],
      y[a] * x[c]  +  y[c] * x[d],
      y[b] * x[c]  +  y[d] * x[d],
      y[a] * x[e]  +  y[c] * x[f]  +  y[e],
      y[b] * x[e]  +  y[d] * x[f]  +  y[f],
    ];
}

sub mdiv(\num, \denom, Bool $div-err is rw) {
    if num =~= 0 {
        0.0
    }
    elsif denom =~= 0 {
        $div-err = True;
        0.0
    }
    else {
        num / denom;
    }
}

#| calculate an inverse, if possible
our sub inverse(TransformMatrix \m --> TransformMatrix) is export(:inverse) {

    my Bool $div-err;
    my \Ib = mdiv( m[b], m[c] * m[b] - m[d] * m[a], $div-err);
    my \Ia = mdiv(1 - m[c] * Ib, m[a], $div-err);

    my \Id = mdiv(m[a], m[a] * m[d] - m[b] * m[c], $div-err);
    my \Ic = mdiv(1 - m[d] * Id, m[b], $div-err);

    my \If = mdiv(m[f] * m[a] - m[b] * m[e], m[b] * m[c] - m[a] * m[d], $div-err);
    my \Ie = mdiv(- m[e] - m[c] * If, m[a], $div-err);

    if $div-err {
        warn "unable to invert matrix: {m}";
        identity();
    }
    else {
        [ Ia, Ib, Ic, Id, Ie, If, ];
    }
}

#| Coordinate transform (or dot product) of x, y
our sub dot(TransformMatrix \m, Numeric \x, Numeric \y) is export(:dot) {
    my \tx = m[a] * x  +  m[c] * y  +  m[e];
    my \ty = m[b] * x  +  m[d] * y  +  m[f];
    (tx, ty);
}
=code    x' = a.x  + c.y + e; y' = b.x + d.y +f
=para See [PDF 1.7 Section 4.2.3 Transformation Matrices]

#| inverse of the above. Convert from untransformed to transformed space
our sub inverse-dot(TransformMatrix \m, Numeric \tx, Numeric \ty) is export(:inverse-dot) {
    # nb two different simultaneous equations for the above.
    my ($x, $y);
    my \div1 = m[d] * m[a]  -  m[c] * m[b];
    if div1|m[a] !=~= 0.0 {
        $y = (ty * m[a]  - m[b] * tx + m[e] * m[b]  -  m[f] * m[a]) / div1;
        $x = (tx  -  m[c] * $y  -  m[e]) / m[a];
    }
    else {
        my \div2 = m[b] * m[c]  -  m[a] * m[d];
        if div2|m[c] !=~= 0  {
            $x = (ty * m[c]  +  m[d] * m[e]  - m[f] * m[c] - m[d] * tx) / div2;
            $y = (tx  -  m[a] * $x  -  m[e]) / m[c];
        }
        else {
            die "unable to compute coordinates";
        }
    }
    ($x, $y);
}

#| Compute: $a = $a X $b
our sub apply(TransformMatrix $a! is rw, TransformMatrix $b! --> TransformMatrix) is export(:apply) {
    $a .= &multiply($b);
}

#| return true of this is the identity matrix =~= [1, 0, 0, 1, 0, 0 ]
our sub is-identity(TransformMatrix \m) is export(:is-identity) {
    ! (m.list Z identity()).first: { .[0] !=~= .[1] };
}

#| round to 6 decimal places. convert to int, if there's no further precision loss
our sub round(Numeric \n) {
    my Numeric $r = n.round(1e-6);
    my int $i = n.round;
    $r == $i ?? $i !! $r;
}

#| Apply a set of transforms.
our sub transform(
    :$matrix = identity(),
    :$translate,
    :$rotate,
    :$reflect,
    :$scale,
    :$skew,
    --> TransformMatrix
    ) is export(:transform) {
    my TransformMatrix $t = $matrix.Array;
    apply($t, translate( |$_ )) with $translate;
    apply($t, rotate( $_ ))     with $rotate;
    apply($t, reflect( $_ ))    with $reflect;
    apply($t, scale( |$_ ))     with $scale;
    apply($t, skew( |$_ ))      with $skew;
    [ $t.map: { round($_) } ];
}
=para Order of transforms is: 1. Translate  2. Rotate 3. Reflect 4. Scale/Skew
=para See [PDF 1.7 Section 4.2.2 Common Transforms]

