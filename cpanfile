requires   "IO::Handle";
requires   "XSLoader";

recommends "Encode"                   => "3.19";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.22";
    };

on "build" => sub {
    requires   "Config";
    };

on "test" => sub {
    requires   "Test::More";
    requires   "Tie::Scalar";
    };
