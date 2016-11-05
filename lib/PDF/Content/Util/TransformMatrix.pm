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

    our sub identity returns TransformMatrix {
        [1, 0, 0, 1, 0, 0];
    }

    our sub translate(Numeric $x!, Numeric $y = $x --> TransformMatrix) {
        [1, 0, 0, 1, $x, $y];
    }

    our sub rotate( Numeric \deg --> TransformMatrix) {
        my Numeric \r = deg2rad(deg);
        my Numeric \cos = cos(r);
        my Numeric \sin = sin(r);

        [cos, sin, -sin, cos, 0, 0];
    }

    our sub scale(Numeric $x!, Numeric $y = $x --> TransformMatrix) {
        [$x, 0, 0, $y, 0, 0];
    }

    our sub skew(Numeric $x, Numeric $y = $x --> TransformMatrix) {
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
    #| caculate an inverse, if possible
    our sub inverse(TransformMatrix \m) {

        #| todo: sensitive to divides by zero. Is there a better algorithm?
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
    #|    x' = a.x  + c.y + e; y' = b.x + d.y +f
    #| See [PDF 1.7 Section 4.2.3 Transformation Matrices]
    our sub dot(TransformMatrix \m, Numeric \x, Numeric \y) {
	my \tx = m[a]*x + m[c]*y + m[e];
	my \ty = m[b]*x + m[d]*y + m[f];
        (tx, ty);
    }

    #| inverse of the above. Convert from untransformed to transformed space
    our sub inverse-dot(TransformMatrix \m, Numeric \tx, Numeric \ty) {
        # nb two different simultaneous equations for the above.
        # there are further solutions. Could be alternate fomulation?
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
    our sub apply(TransformMatrix $a! is rw, TransformMatrix $b! --> TransformMatrix) {
	$a = multiply($a, $b);
    }

    # return true of this is the identity matrix =~= [1, 0, 0, 1, 0, 0 ]
    our sub is-identity(TransformMatrix \m) {
        ! (m.list Z identity()).first: { .[0] !=~= .[1] };
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
