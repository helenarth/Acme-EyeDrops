# For this package, .eye files are treated essentially the
# same as .pm files in the lib/Acme directory. To achieve
# that we must derive a new My::Builder class as shown below
# (only works with v0.17 or later of Module::Build).
# A later version of Module::Build will make this My::Builder
# class unnecessary with a new pm_files parameter.

use strict;
use Module::Build;

my $class = Module::Build->subclass(
   class => 'My::Builder',
   code => q{
      sub find_pm_files {
         my $self = shift;
         $self->{properties}{pm_files} ||
            $self->rscan_dir('lib', qr{\.(?:eye|pm)$});
      }
   }
);

my $m = $class->new(
   module_name => 'Acme::EyeDrops',
   license => 'perl',
   requires => {perl => '5.005_03' },
   build_requires => { 'Module::Build' => 0.17 }
);
$m->create_build_script;
