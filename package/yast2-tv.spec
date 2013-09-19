#
# spec file for package yast2-tv
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-tv
Version:        3.1.0
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:	        System/YaST
License:        GPL-2.0+
BuildRequires:  perl-XML-Writer update-desktop-files yast2 yast2-sound yast2-testsuite
BuildRequires:  yast2-devtools >= 3.0.6

# .modprobe_blacklist agent
Requires:	yast2-core >= 2.16.19
# GetInstArgs::automatic_configuration
Requires:	yast2 >= 2.21.22
Requires:	yast2-sound
Provides:	yast2-config-tv yast2-db-tv
Obsoletes:	yast2-config-tv yast2-db-tv
Provides:	yast2-lib-hardware
Obsoletes:	yast2-lib-hardware
Provides:	yast2-trans-tv
Obsoletes:	yast2-trans-tv
PreReq:		sed

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - TV Configuration

%description
This package contains the YaST2 component for TV card configuration.

%package devel-doc
Requires:       yast2-tv = %version
Group:          System/YaST
Summary:        YaST2 - TV Configuration - Development Documentation

%description devel-doc
This package contains development documentation for using the API
provided by this package.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%post
# rename the config file to the new modprobe schema
if test -e /etc/modprobe.d/tv; then
    mv -f /etc/modprobe.d/tv /etc/modprobe.d/50-tv.conf
fi

# comment out bit_test option (bnc#712023)
if test -e /etc/modprobe.d/50-tv.conf; then
    sed -i -e 's/^\([ \t]*options[ \t]*i2c-algo-bit[ \t]*bit_test=1\)/# \1/' /etc/modprobe.d/50-tv.conf
fi


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/tv
%{yast_yncludedir}/tv/*
%{yast_clientdir}/*.rb
%{yast_moduledir}/*.*
%{yast_desktopdir}/*.desktop
%{yast_scrconfdir}/*.scr
%{yast_ydatadir}/*.yml
%dir %{yast_docdir}
%doc %{yast_docdir}/README
%doc %{yast_docdir}/COPYING
%doc %{yast_docdir}/tv-features.md

%files devel-doc
%doc %{yast_docdir}/autodocs
%doc %{yast_docdir}/tv-specification.md
