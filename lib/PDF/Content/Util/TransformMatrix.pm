use v6;

module PDF::Content::Util::TransformMatrix {

    # Designed to work on PDF text and graphics transformation matrices of the form:
    #
    # [ a b 0 ]
    # [ c d 0 ]
    # [ e f 1 ]
    #
    # where a b c d e f are stored in a six digit array and the third column is implied.

    sub deg2rad(Numeric \deg) {
        return deg * pi / 180;
    }

    subset TransformMatrix of Array where {.elems == 6}
    my Int enum TransformMatrixElem « :a(0) :b(1) :c(2) :d(3) :e(4) :f(5) »;

    sub identity returns TransformMatrix {
        [1, 0, 0, 1, 0, 0];
    }

    sub translate(Numeric $x!, Numeric $y = $x --> TransformMatrix) {
        [1, 0, 0, 1, $x, $y];
    }

    sub rotate( Numeric \deg --> TransformMatrix) {
        my Numeric \r = deg2rad(deg);
        my Numeric \cos = cos(r);
        my Numeric \sin = sin(r);

        [cos, sin, -sin, cos, 0, 0];
    }

    sub scale(Numeric $x!, Numeric $y = $x --> TransformMatrix) {
        [$x, 0, 0, $y, 0, 0];
    }

    sub skew(Numeric $x, Numeric $y = $x --> TransformMatrix) {
        [1, tan(deg2rad($x)), tan(deg2rad($y)), 1, 0, 0];
    }

    #| multiply transform matrix x X y
    our sub multiply(TransformMatrix \x, TransformMatrix \y --> TransformMatrix) {

        [ y[a]*x[a] + y[c]*x[b],
          y[b]*x[a] + y[d]*x[b],
          y[a]*x[c] + y[c]*x[d],
          y[b]*x[c] + y[d]*x[d],
          y[a]*x[e] + y[c]*x[f] + y[e],
          y[b]*x[e] + y[d]*x[f] + y[f],
        ];
    }

    #| Coordinate transfrom of x, y: See [PDF 1.7 Sectiono 4.2.3 Transformation Matrices]
    #|  x' = a.x  + c.y + e; y' = b.x + d.y +f
    our sub transform(TransformMatrix \tm, Numeric \x, Numeric \y) {
	[ tm[a]*x + tm[c]*y + tm[e],
	  tm[b]*x + tm[d]*y + tm[f], ]
    }

    #| Compute: $a = $a X $b
    our sub apply(TransformMatrix $a! is rw, TransformMatrix $b! --> TransformMatrix) {
	$a = multiply($a, $b);
    }

    # return true of this is the identity matrix =~= [1, 0, 0, 1, 0, 0 ]
    our sub is-identity(TransformMatrix \m) {
        ! (m.list Z identity()).first: { .[0] !=~= .[1] };
    }

    #| caculate an inverse, if possible
    our sub inverse(TransformMatrix \m) {

        #| todo: sensitive to divides by zero. Is there a better algorithm?
        my $div0;
        sub mdiv(\num, \denom) {num =~= 0 ?? 0.0 !! denom =~= 0 ?? do {$div0++; 1.0} !! num / denom; } 
        my \Ib =  mdiv( m[b], m[c] * m[b] - m[d] * m[a]);
        my \Ia = mdiv(1 - m[c] * Ib, m[a]);

        my \Id = mdiv(m[a], m[a] * m[d] - m[b] * m[c]);
        my \Ic = mdiv(1 - m[d] * Id, m[b]);

        my \If = mdiv(m[f] * m[a] - m[b] * m[e], m[b] * m[c] - m[a] * m[d]);
        my \Ie = mdiv(0 - m[e] - m[c] * If, m[a]);

        with $div0 {
            warn "unable to invert matrix: {m}";
            identity();
        }
        else {
            [ Ia, Ib, Ic, Id, Ie, If, ];
        }
    }

    our sub round(Numeric \n) {
	my Numeric \r = n.round(1e-6);
	my Int \i = n.round;
	constant Epsilon = 1e-5;
	abs(n - i) < Epsilon
	    ?? i   # assume it's an int
	    !! r;
    }

    multi sub vect(Numeric $n! --> List) {@($n, $n)}
    multi sub vect(Array $v where {+$v == 2} --> List) {@$v}

    #| 3 [PDF 1.7 Section 4.2.2 Common Transforms
    #| order of transforms is: 1. Translate  2. Rotate 3. Scale/Skew

    our sub transform-matrix(
	:$translate,
	:$rotate,
	:$scale,
	:$skew,
	:$matrix,
	--> TransformMatrix
	) {
	my TransformMatrix $t = identity();
	apply($t, translate( |vect($_) )) with $translate;
	apply($t, rotate( $_ ))           with $rotate;
	apply($t, scale( |vect($_) ))     with $scale;
	apply($t, skew( |vect($_) ))      with $skew;
	apply($t, $_)                     with $matrix;
	[ $t.map: { round($_) } ];
    }


}
