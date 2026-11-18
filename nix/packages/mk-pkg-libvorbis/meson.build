# https://mesonbuild.com/External-Project-module.html

project('libvorbis', 'c')

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
        '--disable-tests'
    ] + tool_options,
    verbose: true,
)

libvorbis_dep = p.dependency('libvorbis')
meson.override_dependency('libvorbis', libvorbis_dep)
