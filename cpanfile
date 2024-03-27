requires   "IO::Handle";
requires   "XSLoader";

recommends "Encode"                   => "3.21";

on "configure" => sub {
    requires   "ExtUtils::MakeMaker";

    recommends "ExtUtils::MakeMaker"      => "7.70";
    };

on "build" => sub {
    requires   "Config";
    };

on "test" => sub {
    requires   "Test::More";
    requires   "Tie::Scalar";
    };
