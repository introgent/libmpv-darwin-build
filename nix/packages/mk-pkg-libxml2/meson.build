# https://mesonbuild.com/External-Project-module.html

project('libxml2', 'c')

mod = import('unstable-external_project')

# The cross file's tools, handed to configure: libtool 2.5 (libass 0.17.2
# and later) links a static convenience library, which needs ar and ranlib,
# and configure finds none on its own here.
tool_options = []
foreach tool : ['ar', 'ranlib', 'nm', 'strip']
    tool_options += tool.to_upper() + '=' + find_program(tool).full_path()
endforeach

p = mod.add_project('configure',
    configure_options : [
        '--prefix=@PREFIX@',
        '--disable-static',
        '--enable-shared',
        '--disable-dependency-tracking',
        '--disable-silent-rules',
        '--without-python'
    ] + tool_options,
    verbose: true,
)

libxml2_dep = p.dependency('libxml2')
meson.override_dependency('libxml2', libxml2_dep)
