if (-e squid) then
    rm -rf squid
endif
mkdir squid
/tool/pandora64/bin/python3.9 -m venv squid
# hack ./bin/activate.csh as $source_dir/script/activate.csh
deactivate
cp -rf /tool/aticad/1.0/src/zoo/PD_agent/tile/activate_mod.csh squid/bin/activate.csh
chmod 766 squid/bin/activate.csh
set env_path = `resolve squid`
sed -i "s@REPLACE_ENV_PATH@$env_path@g" squid/bin/activate.csh
source squid/bin/activate.csh
foreach f (`cat /tool/aticad/1.0/src/zoo/PD_agent/tile/pip.list`)
    echo "pip install $f"  
    pip install $f
end

