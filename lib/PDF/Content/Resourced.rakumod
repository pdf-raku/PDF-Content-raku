#| roles for an object with a /Resources entry. E.g. Page or XObject form
unit role PDF::Content::Resourced;

method !resource-dict { self.Resources //= {} }

method core-font(|c) {
    self!resource-dict.core-font(|c);
}
method use-font($obj, |c) {
    self!resource-dict.use-font($obj, |c);
}
method use-resource($obj, |c) {
    self!resource-dict.resource($obj, |c);
}
method resource-key($obj, |c) {
    self!resource-dict.resource-key($obj, |c);
}

#| my %fonts = $pdf.page(1).resources('Font');
multi method resources('ProcSet') {
    my @entries;
    with self.Resources {
        with <ProcSet> -> List $r {
            @entries = $r.keys.map: { $r[$_] };
        }
    }
    @entries;
}
multi method resources(Str $type) {
    my %entries;
    with self.Resources {
        with .{$type} -> Hash $r {
            %entries = $r.keys.map: { $_ => $r{$_} };
        }
    }
    %entries;
}

method resource-entry(|c) {
    .resource-entry(|c) with self.Resources;
}

method find-resource(|c ) {
    .find-resource(|c)
        with self.Resources;
}

method images(Bool :$inline = True) {
    my %forms = self.resources: 'XObject';
    my @images = %forms.values.grep( *.<Subtype> eq 'Image');
    @images.append: self.gfx.inline-images
        if $inline;
    @images;
}
