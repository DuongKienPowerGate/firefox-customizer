#!/bin/bash

# Addons
#
addons=(
  'ublock-origin'
  'privacy-badger17'
  'google-search-link-fix'
  'i-dont-care-about-cookies'
  'youtube-ssl'
  'startpage-ssl'
  'imdb'
  'duck-duck-go-ssl'
  'wikipedia-de'
  'github'
  'debian-packages'
  'linux-manpages'
  'docker-hub'
  'php-manual-search'
  'openstreetmap-1'
  'google-no-country-redirect'
  'google-encrypted-search'
  'search-google-images'
  'google-video-search-10562'
)

# Search engines and possibly aliases
#
searches=(
  # Existing, but add alias
  'amazondotcom=a'
  'ebay-ch=e'
  'wikipedia=w'
  # New
  'youtube-ssl=y'
  'startpage-ssl=s'
  'imdb=i'
  'duckduckgo-ssl=d'
  'wikipedia-de=wde'
  'github=git'
  'debian-packages=deb'
  'linux-manpages=man'
  'docker-hub=hub'
  'php-manual-search=php'
  'openstreetmap-1=o'
  'google-no-country-redirect=gen'
  'google-encrypted-search=g'
  'search-google-images=gi'
  'google-video-search-10562=gv'
)

jq '.engines[] | ."_shortName"' search.json

jq '.engines[] | if select(."_shortName" == "google") then ."_metaData"+={"alias":"kaas"} else . end' search.json 



# Preferences (prefs.js)
#
preferences=(
  # Enable devtool, to be able to update search engines
  'devtools.chrome.enabled=true'
  # Disable accessibility service
  'accessibility.force_disabled=1'
  # Disable firstrun clickthrough tutorials
  'browser.onboarding.enabled=false'
  # Disable to send health report
  'datareporting.healthreport.service.firstRun=true'
  'datareporting.healthreport.uploadEnabled=false'
  # Make about:blank the startpage
  'browser.startup.homepage="about:blank"'
  'browser.startup.page=0'
  # Stop domain guessing
  'browser.fixup.alternate.enabled=false'
  # Don't remember passwords
  'signon.rememberSignons=false'
  # Do not track
  'privacy.donottrackheader.enabled=true'
  # Private browsing mode enabled
  'browser.privatebrowsing.autostart=true'
  # No remember histroy in URL bar
  'browser.urlbar.suggest.history=false'
  # No search suggestions in URL bar (also unset in DuckduckGo Addon)
  'browser.search.suggest.enabled=false'
  # No "one off" search buttons
  'browser.urlbar.oneOffSearches=false'
  # New page tab clean
  'browser.newtabpage.enabled=false'
  'browser.newtabpage.enhanced=false'
  'browser.newtabpage.introShown=true'
  'browser.tabs.loadInBackground=false'
  # Tracking Protection
  'privacy.trackingprotection.enabled=true'
  'privacy.trackingprotection.introCount=20'
  'urlclassifier.trackingTable="test-track-simple,base-track-digest256,content-track-digest256"'
  # URL stop protocol hide and stop domain highlighting
  'browser.urlbar.formatting.enabled=false'
  'browser.urlbar.trimURLs=false'
  # Get rid of Pocket
  'extensions.pocket.enabled=false'
  # Get rid of Reader
  'reader.parse-on-load.enabled=false'
  # Get rid of Geolocation
  'geo.enabled=false'
  # Get rid of scrrenshot functionality
  'extensions.screenshots.disabled=true'
  # Get rid of the bookmark star in the address bar
  'browser.pageActions.persistedActions="{\"version\":1,\"ids\":[\"bookmark\"],\"idsInUrlbar\":[]}"'
)

# Addon coustomizations (strings in the form '[path_to_json_file_under_browser_extension_data]%[jq-filter]'
#
addon_customizations=(
  # Remove contect menu entry for i-cont-care-about-cookies
  'jid1-KKzOGWgsW3Ao4Q@jetpack/storage.js%{"contextmenu":false,"whitelisted_domains":{}}'
  # Say I saw the "comic" (introduction stuff) for Privacy Badger
  'jid1-MnnxcxisBPnSXQ@jetpack/storage.js%.settings_map.seenComic=true'
  # Add new lists to uBlock Origin
  'uBlock0@raymondhill.net/storage.js%.selectedFilterLists+=["DEU-0","fanboy-annoyance","adguard-annoyance","awrl-0"]'
  # Prevent WebRCT local IP address leak (through uBlock Origin)
  'uBlock0@raymondhill.net/storage.js%.+={"webrtcIPAddressHidden":true}'
)

# Toolbar content customizations ("browser.uiCustomization.state" in prefs.js)
#
toolbar_content_customizations=(
  'PanelUI-contents=edit-controls,zoom-controls,new-window-button,privatebrowsing-button,save-page-button,print-button,history-panelmenu,fullscreen-button,find-button,preferences-button,add-ons-button'
  'nav-bar=back-button,forward-button,urlbar-container'
  'PersonalToolbar=personal-bookmarks,ctraddon_bookmarks-menu-toolbar-button'
  'TabsToolbar=tabbrowser-tabs,new-tab-button,ctraddon_tabs-closebutton'
)

# Toolbar visibility customizations (xulstore.json)
#
toolbar_visibility_customizations=(
  'toolbar-menubar="autohide":"false","currentset":"menubar-items"'
)

# userChrome.css
#
userchrome_contents="/* Hide the Hamburger button */
#PanelUI-menu-button {
    display: none;
}

/* Hide the Page Action button (three dots in the address bar) */
#pageActionButton {
    display: none !important;
}
"


pid=`ps -e | grep " firefox$" | xargs | cut -d" " -f1`

if [[ -n "$pid" ]]; then
  echo "Firefox is running, please close all instances first!"
  exit 1
fi

mkdir -p build/
cd build/

echo -n "Get and build dejsonlz4/jsonlz4 tools (as long as Firefox does not use the standard format for search.json compression) ..."

git clone https://github.com/avih/dejsonlz4.git
cd dejsonlz4
gcc -Wall -o dejsonlz4 src/dejsonlz4.c src/lz4.c
gcc -Wall -o jsonlz4 src/ref_compress/jsonlz4.c src/lz4.c
cd ..

echo " OK"

echo -n "Starting Firefox to install addons. For each click '+ Add to Firefox', then 'Add' and finally close the browser ..."

for addon in ${addons[@]}; do
    firefox https://addons.mozilla.org/en-US/firefox/addon/${addon}/
done

echo " OK"

profile_dir=`echo ~/.mozilla/firefox/*.default/`

echo -n "Updating prefs.js "

file="${profile_dir}prefs.js"

for preference in ${preferences[@]}; do
  parts=(${preference//=/ })
  key=${parts[0]}
  value=${parts[1]}
  sed -i 's/^.*${key}.*$//g' $file
  if [[ -n "$value" ]]; then
    echo "user_pref(\"${key}\", ${value});" >> $file
  fi
  echo -n "."
done

echo " OK"

echo -n "Updating addon configurations "

for customization in ${addon_customizations[@]}; do
  parts=(${customization//%/ })
  relative_filename=${parts[0]}
  jq_filter=${parts[1]}

  file="${profile_dir}browser-extension-data/${relative_filename}"

  if [ -f $file ]; then
    cp $file temp.json
    jq "${jq_filter}" temp.json > $file
  else
    jq -n "${jq_filter}" > $file
    chmod 600 $file
  fi

  echo -n "."
done

echo " OK"

echo -n "Customizing toolbar contents "

file="${profile_dir}prefs.js"

workfile=toolbar.json

grep "browser.uiCustomization.state" $file | sed 's/^.*"browser.uiCustomization.state", "\(.*\)");$/\1/' | sed 's/\\"/"/g' > $workfile

for customization in ${toolbar_content_customizations[@]}; do
  parts=(${customization//=/ })
  name=${parts[0]}
  elements=(${parts[1]//,/ })

  # I somehow didn't manage to look for all characters except "]", therefore
  # using ":", which should be safe as long as there is no further nesting of
  # "placements" items
  sed -i "s/\"${name}\":\[[^:]*\],\?//g" $workfile

  if [[ ${#elements[@]} -gt 0 ]]; then
    element_list=`printf "%s\",\"" "${elements[@]}"`

    toolbar_json="\"${name}\":[\"${element_list%???}\"],"

    sed -i "s/\(\"placements\":{\)/\1${toolbar_json}/" $workfile
  fi
  echo -n "."
done

sed -i "s/,}/}/g" $workfile

customized_json=`sed 's/"/\\\"/g' $workfile`

sed -i 's/^.*browser.uiCustomization.state.*$//g' $file
echo "user_pref(\"browser.uiCustomization.state\", \"${customized_json}\");" >> $file

echo " OK"

echo -n "Updating toolbar visibilities "

file="${profile_dir}xulstore.json"

for customization in ${toolbar_visibility_customizations[@]}; do
  parts=(${customization//=/ })
  name=${parts[0]}
  content=${parts[1]}

  sed -i "s/\"${name}\":{[^}]*},\?//g" $file

  if [[ -n "$content" ]]; then
    toolbar_json="\"${name}\":{${content}},"

    sed -i "s/\(\"chrome:\/\/browser\/content\/browser.xul\":{\)/\1${toolbar_json}/" $file
  fi
  echo -n "."
done

sed -i "s/,}/}/g" $file

echo " OK"

echo -n "Creating userChrome.css ..."

mkdir -p ${profile_dir}chrome

file="${profile_dir}chrome/userChrome.css"

echo "$userchrome_contents" > $file

echo " OK"

cd ..
rm -rf build/
