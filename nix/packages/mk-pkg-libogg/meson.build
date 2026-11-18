# https://mesonbuild.com/External-Project-module.html

project('libogg', 'c')

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
    ] + tool_options,
    verbose: true,
)

libogg_dep = p.dependency('libogg')
meson.override_dependency('libogg', libogg_dep)
