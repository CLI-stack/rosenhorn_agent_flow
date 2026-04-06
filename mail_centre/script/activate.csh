# This file must be used with "source bin/activate.csh" *from csh*.
# You cannot run it directly.
# Created by Davide Di Blasi <davidedb@gmail.com>.
# Ported to Python 3.3 venv by Andrew Svetlov <andrew.svetlov@gmail.com>

alias deactivate 'test $?_OLD_VIRTUAL_PATH != 0 && setenv PATH "$_OLD_VIRTUAL_PATH" && unset _OLD_VIRTUAL_PATH; rehash; test $?_OLD_VIRTUAL_PROMPT != 0 && set prompt="$_OLD_VIRTUAL_PROMPT" && unset _OLD_VIRTUAL_PROMPT; unsetenv VIRTUAL_ENV; test "\!:*" != "nondestructive" && unalias deactivate'

# Unset irrelevant variables.
deactivate nondestructive

setenv VIRTUAL_ENV "/proj/wek_pd_irem1/simchen/squid"

set _OLD_VIRTUAL_PATH="$PATH"
setenv PATH "$VIRTUAL_ENV/bin:$PATH"


if ("" != "") then
    set env_name = ""
else
    set env_name = `basename "$VIRTUAL_ENV"`
endif

# Could be in a non-interactive environment,
# in which case, $prompt is undefined and we wouldn't
# care about the prompt anyway.
if ( $?prompt ) then
    set _OLD_VIRTUAL_PROMPT="$prompt"
    set prompt = "[$env_name] $prompt"
endif

unset env_name

alias pydoc python -m pydoc
setenv PYTHONPATH "/tool/cbar/apps/oascript/3.3/python:/tool/amd/rex/Rev:/tool/aticad/1.0/mod:/proj/rtg-soc-pd-nobackup/PDI_platform/TileBuilder/python:/proj/rtg-soc-pd-nobackup/PDI_platform/TileBuilder/util:/proj/rtg-soc-pd-nobackup/PDI_platform/fullchipfloorplan:/proj/rtg-soc-pd-nobackup/PDI_platform/scripts/python:/proj/rtg-soc-pd-nobackup/PDI_platform/scripts/util:/tool/amd/rex/Rev:/tool/aticad/1.0/mod"

rehash
