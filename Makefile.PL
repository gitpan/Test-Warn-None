# $Header: /home/fergal/my/cvs/Test-Deep/Makefile.PL,v 1.3 2003/06/18 12:30:14 fergal Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
	AUTHOR => 'Fergal Daly <fergal@esatclear.ie>',
	NAME => 'Test::Warn::None',
	VERSION_FROM => './lib/Test/Warn/None.pm',
	INSTALLDIRS => 'perl',
	PREREQ_PM => {
		Test::Tester => '0.04',
	}
);
