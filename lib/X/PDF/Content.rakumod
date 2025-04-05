class X::PDF::Content {
    use X::PDF;
    also is X::PDF;
}

class X::PDF::Content::OP is X::PDF::Content {
    has Str $.op is required;
    has Str $.mnemonic;
    method message { "Error processing '$.op' ($!mnemonic) operator" }
}

class X::PDF::Content::OP::Unexpected
    is X::PDF::Content::OP {
    has Str $.type is required;
    has Str $.where is required;
    method message { "$!type operation '$.op' ($.mnemonic) used $!where" }
}

class X::PDF::Content::OP::BadNesting
    is X::PDF::Content::OP {
    has Str $.opener;
    method message {
        "Bad nesting; '$.op' ($.mnemonic) operator not matched by preceeding $!opener"
    }
}

class X::PDF::Content::OP::BadNesting::MarkedContent
    is X::PDF::Content::OP::BadNesting {
        method message { "Illegal nesting of marked content tags" }
}

class X::PDF::Content::OP::Error
    is X::PDF::Content::OP {
    has Exception $.error is required;
    method message { callsame() ~ ": {$!error.message}" }
}

class X::PDF::Content::OP::Unknown
    is X::PDF::Content::OP {
    method message { "Unknown content operator: '$.op'" }
}

class X::PDF::Content::OP::BadArrayArg
    is X::PDF::Content::OP {
    has $.arg is required;
    method message { "Invalid entry in '$.op' ($.mnemonic) array: {$!arg.raku}" }
}

class X::PDF::Content::OP::BadArg
    is X::PDF::Content::OP {
    has $.arg is required;
    method message { "Bad '$.op' ($.mnemonic) argument: {$!arg.raku}" }
}

class X::PDF::Content::OP::BadArgs
    is X::PDF::Content::OP {
    has @.args is required;
    method message { "Bad '$.op' ($.mnemonic) argument list: {@!args».raku.join: ', '}" }
}

class X::PDF::Content::OP::TooFewArgs
    is X::PDF::Content::OP {
    method message { "Too few arguments to '$.op' ($.mnemonic)" }
}

class X::PDF::Content::OP::ArgCount
    is X::PDF::Content::OP {
    has Str $.error is required;
    method message { "Incorrect number of arguments in '$.op' ($.mnemonic) command, $!error" }
}

class X::PDF::Content::Unclosed
    is X::PDF::Content {
    has Str $.message is required;
}

class X::PDF::Content::ParseError
    is X::PDF::Content {
    has Str $.content is required;
    method message {"Unable to parse content stream: $!content";}
}

class X::PDF::Content::UnknownResource
    is X::PDF::Content {
    has Str $.type is required;
    has Str $.key is required;
    method message { "Unknown $!type resource: /$!key" }
}

class  X::PDF::Content::Image is X::PDF::Content { }

class X::PDF::Content::Image::WrongHeader is X::PDF::Content::Image {
    has Str $.type is required;
    has Str $.header is required;
    has $.path is required;
    method message {
        "$!path image doesn't have a $!type header: {$.header.raku}"
    }
}

class X::PDF::Content::Image::UnknownType is X::PDF::Content::Image {
    has $.path is required;
    method message {
        "Unable to open as an image: $!path";
    }
}

class X::PDF::Content::Image::UnknownMimeType is X::PDF::Content::Image {
    has $.path is required;
    has $.mime-type is required;
    method message {
        "Expected mime-type 'image/*' or 'application/pdf', got '$!mime-type': $!path"
    }
}

