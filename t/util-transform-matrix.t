use v6;
use Test;
use PDF::Content::Util::TransformMatrix;

my @identity = PDF::Content::Util::TransformMatrix::transform();
is-deeply @identity, [1, 0, 0, 1, 0, 0], 'null transform';

my @translated = PDF::Content::Util::TransformMatrix::transform(:translate[10, 20]);
is-deeply @translated, [1, 0, 0, 1, 10, 20], 'translate transform';

is-deeply PDF::Content::Util::TransformMatrix::transform(:translate(30)), [1, 0, 0, 1, 30, 30], 'translate transform';

my @rotated = PDF::Content::Util::TransformMatrix::transform(:rotate(pi/2) );
is-deeply @rotated, [0, 1, -1, 0, 0, 0], 'rotate transform';

my @scaled = PDF::Content::Util::TransformMatrix::transform(:scale(1.5));
is-deeply @scaled, [1.5e0, 0, 0, 1.5e0, 0, 0], 'scale transform';
is-deeply PDF::Content::Util::TransformMatrix::transform(:scale[1.5, 2.5]), [1.5e0, 0, 0, 2.5e0, 0, 0], 'scale transform';

is-deeply PDF::Content::Util::TransformMatrix::dot(@identity, 10, 20), (10, 20), 'identity dot product';
is-deeply PDF::Content::Util::TransformMatrix::dot(@translated, 10, 20), (20, 40), 'translated dot product';
is-deeply PDF::Content::Util::TransformMatrix::dot(@rotated, 10, 20), (-20, 10), 'rotated dot product';
is-deeply PDF::Content::Util::TransformMatrix::dot(@scaled, 10, 20), (15e0, 30e0), 'scaled dot product';

sub deg2rad(Numeric \deg) {
    return deg * pi / 180;
}

my $skew = PDF::Content::Util::TransformMatrix::transform( :skew(deg2rad(10)));
is-approx $skew[1], 0.176327, 'skew transform';
is-approx $skew[2], 0.176327, 'skew transform';

$skew = PDF::Content::Util::TransformMatrix::transform(:skew[deg2rad(10), deg2rad(20)]);
is-approx $skew[1], 0.176327, 'skew transform';
is-approx $skew[2], 0.36397, 'skew transform';

my $chained = PDF::Content::Util::TransformMatrix::transform(
    :translate[10, 20],
    :rotate(1.5 * pi),
    :scale(2) );

is-deeply $chained, [0, -2, 2, 0, 40, -20], 'chained transforms';

is-deeply PDF::Content::Util::TransformMatrix::multiply([1,2,3,4,5,6], [10,20,30,40,50,60]), [70, 100, 150, 220, 280, 400], 'multiply matrix';

my $tform = PDF::Content::Util::TransformMatrix::transform(
    :translate[10, 20],
    :scale(2) );

is-deeply [ PDF::Content::Util::TransformMatrix::dot($tform, 5, 15) ], [(10 + 5) * 2, (20 + 15) * 2], 'dot';

is-deeply [ PDF::Content::Util::TransformMatrix::dot($tform, 25, 30) ], [70, 100], 'dot';

is-deeply [ PDF::Content::Util::TransformMatrix::inverse-dot($tform, 70, 100) ], [25.0, 30.0], 'inverse-dot';

my @inv = PDF::Content::Util::TransformMatrix::inverse($tform);
is-deeply @inv, [0.5, 0.0, 0.0, 0.5, -10.0, -20.0], 'inverse';
my @id = PDF::Content::Util::TransformMatrix::multiply($tform, @inv);
is-deeply @id, [1.0, 0.0, 0.0, 1.0, 0.0, 0.0], 'inverse multiplication';

ok PDF::Content::Util::TransformMatrix::is-identity(@id), 'identity';
@id[1]+= .2;
nok PDF::Content::Util::TransformMatrix::is-identity(@id), 'non-identity';

done-testing;
